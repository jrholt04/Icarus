#!/usr/bin/ruby
#File: book.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   this page is for authenticating the user and returning the image url for the user to display on the front end.

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
for author in authors
    
    query = <<~GRAPHQL
    {
        authors(where: { name: { _eq: "#{author['name']}" }, image_id: { _is_null: false } }, limit: 1) {
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
    
    payload = JSON.parse(res.body)
    imgUrl = payload.dig('data', 'authors', 0, 'image', 'url') 

    if imgUrl == nil   
        db.query("UPDATE Authors SET headshot = NULL WHERE auth_id = #{author['auth_id']};")
    else 
        db.query("UPDATE Authors SET headshot = '#{imgUrl}' WHERE auth_id = #{author['auth_id']};")
    end
    puts "Author: #{author['name']} #{author['auth_id'] } Image URL: #{imgUrl}"

end