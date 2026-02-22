#!/usr/bin/ruby

# FILE: authorImgs.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to fetch author headshots from the Pexels API

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

authors = db.query("SELECT auth_id, name FROM Authors;")
failed = 0
success = 0
for author in authors
    headshotUrl = nil
    author_name_raw = author["name"].to_s.strip
    author_name = author_name_raw.gsub(" ", "_")
    encoded_author = URI.encode_www_form_component(author_name) #encodes the name for the query to api so we aviod issues with special characters.

    uri = URI("https://en.wikipedia.org/api/rest_v1/page/summary/#{encoded_author}") 
    res = Net::HTTP.get_response(uri)
    data = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
    
    # Debug output
    puts "Searching for: #{author_name_raw}"
    puts "  Wikipedia page title: #{data&.dig('title')}" if data
    puts "  HTTP Status: #{res.code}"
    
    headshotUrl = data&.dig('thumbnail', 'source')
    if headshotUrl == nil || headshotUrl.empty?
        uri = URI("https://en.wikipedia.org/api/rest_v1/page/summary/#{encoded_author}_(author)") 
        res = Net::HTTP.get_response(uri)
        data = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
        puts "  Fallback search (with author): #{data&.dig('title')}" if data
        headshotUrl = data&.dig('thumbnail', 'source')
    end
    
    if headshotUrl == nil || headshotUrl.empty?
        db.query("UPDATE Authors SET headshot = NULL WHERE auth_id = #{author['auth_id']};")
        puts "  Update Failed - No image found"
        failed += 1
    else 
        db.query("UPDATE Authors SET headshot = '#{db.escape(headshotUrl)}' WHERE auth_id = #{author['auth_id']};")
        puts "  Update Succeeded - #{headshotUrl[0..60]}..."
        success += 1
    end 
    puts ""
end

puts "Total Success: #{success}"
puts "Total Failed: #{failed}"