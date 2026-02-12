#!/usr/bin/ruby
#File: book.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   This is the book page for Icarus

$stdout.sync = true 
$stderr.reopen $stdout 

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'

require_relative '../env_loader'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

#get info from html forms
cgi = CGI.new("html5")

authId = cgi['auth_id'] 

author = db.query("SELECT * FROM Authors WHERE auth_id = #{authId};").first

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Icarus</title>"
puts "        <link rel=\"stylesheet\" href=\"../Icarus.css\">"
puts "    </head>"
puts "    <body>"
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=../index.cgi>Top Books</a></li>"
puts "                <li><a href=\"#search\">Search</a></li>"
puts "                <li><a href=\"#favorites\">Favorites</a></li>"
puts "                <li><a href=\"#reading-log\">Reading Log</a></li>"
puts "                <li><a href=\"#bts\">BTS</a></li>"
puts "                <li><a href=\"#sign-in\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
puts "        <main class=\"author-page\">"
puts "            <div class=\"author-left\">"
puts "                <img class=\"author-photo\" alt=\"Author photo\" src=\"#{author['headshot']}\">"
puts "            </div>"
puts "            <div class=\"author-right\">"
puts "                <h1 class=\"author-titles\">#{author['name']}</h1>"
puts "                <div class=\"author-section\">"
puts "                    <p class=\"author-bio\">#{author['bio']}</p>"
puts "                </div>"
puts "                <h1 class=\"author-titles\">Published Books</h1>"
puts "            </div>"
puts "        </main>"
puts "    </body>"
puts "</html>"  