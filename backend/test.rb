#!/usr/bin/ruby

# File to test ruby code

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

icarusDB = Mysql2::Client.new(:host => '10.20.3.4', :username => 'Icarus', :password => 'B00kz!', :database => 'ss_icarus_db')


authors = icarusDB.query("SELECT auth_id FROM Authors;")
numAuthors = 0
authors.each do |a|
    numAuthors = a
end
puts numAuthors["auth_id"]

weirdAuthor = "Lydia (Goodreads Author)"
authorNames = weirdAuthor.split(" ")
cleanName = ""
authorNames.each do |name|
    if name[0] != "(" && name[name.length() -1] != ")"
        cleanName = cleanName + name + " "
    end
end
puts cleanName

=begin
uri = URI("https://serpapi.com/search.json?engine=google&q=suzanne+collins")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
author = data.dig("knowledge_graph", "description")

puts author
=end