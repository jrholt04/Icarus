#!/usr/bin/ruby
#File: book.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   this script will run and try and populate author images if they are present in the hardcover api.

$stdout.sync = true 
$stderr.reopen $stdout 

require 'mysql2'
require 'cgi'
require 'net/http'
require 'json'
require_relative '../env_loader'

HARDCOVER_API_KEY = ENV['HARDCOVER_API_KEY']
db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))
authors = db.query("SELECT auth_id, name FROM Authors;")

imgUrl = nil
last_request_time = nil
for author in authors
    if last_request_time
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - last_request_time
        sleep(1.0 - elapsed) if elapsed < 1.0
    end
    
    query = <<~GRAPHQL
    {
        authors(where: { name: { _eq: "#{author['name'].to_s}" }, image_id: { _is_null: false } }, limit: 1) {
            image { url }
        }
    }
    GRAPHQL

    uri = URI('https://api.hardcover.app/v1/graphql')
    req = Net::HTTP::Post.new(uri)
    req['content-type'] = 'application/json'
    req['authorization'] = HARDCOVER_API_KEY
    req.body = { query: query }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    last_request_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    payload = JSON.parse(res.body)
    imgUrl = payload.dig('data', 'authors', 0, 'image', 'url') 

    if author['headshot'] == nil #if there is no headshot in the database, try to get one from the hardcover api
        if imgUrl == nil #fall back and try and find the author image based on their book contributions  
            book = db.query("SELECT b.book_id, b.title
                        FROM Books b
                        JOIN BookAuth ba ON ba.book_id = b.book_id
                        WHERE ba.auth_id = #{author['auth_id']}
                        ORDER BY b.title ASC
                        LIMIT 1; ").first
            query = <<~GRAPHQL
            {
                authors(where: { contributions: { book: { title: { _eq: "#{book['title']}" } } } }) {
                    name
                    image { url }
                    id
                }
            }
            GRAPHQL

            uri = URI('https://api.hardcover.app/v1/graphql')
            req = Net::HTTP::Post.new(uri)
            req['content-type'] = 'application/json'
            req['authorization'] = HARDCOVER_API_KEY
            req.body = { query: query }.to_json

            res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
            last_request_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            
            payload = JSON.parse(res.body)

            contributers = payload.dig('data', 'authors')
            for contributers in contributers
                if contributers['name'].to_s.include?(author['name'].to_s) #if the authors name is present in the contributers name, this excludes the extra spaces from hardcase.
                    imgUrl = contributers.dig('image', 'url')
                    db.query("UPDATE Authors SET headshot = '#{imgUrl}' WHERE auth_id = #{author['auth_id']};")
                    break
                end
            end
        else 
            db.query("UPDATE Authors SET headshot = '#{imgUrl}' WHERE auth_id = #{author['auth_id']};")
        end
    end
    puts "Author: #{author['name']} #{author['auth_id'] } Image URL: #{imgUrl}"
end