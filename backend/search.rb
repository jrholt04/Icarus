#!/usr/bin/ruby

# FILE: search.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program that, when given a string, finds any books whose titles contain that string
# Additionally, when given a string, finds any authors whose names contain that string
# Returns an SQL query

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

def findBooks(db, userString) 
    return db.query("SELECT * FROM Books WHERE title LIKE '%" + userString.to_s() + "%';")
end

def findAuthors(db, userString)
    return db.query("SELECT * FROM Authors WHERE name LIKE '%" + userString.to_s() + "%';")
end
