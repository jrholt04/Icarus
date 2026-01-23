#!/usr/bin/ruby
#File: index.cgi
#Azalea Fylnn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   this is the main landing page for Icarus

$stdout.sync = true 
$stderr.reopen $stdout 

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'
require 'stringio'

db = Mysql2::Client.new(
    :host=>'10.20.3.4',
    :username=>'Icarus',
    :password=>'B00kz!',
    :database=>'ss_icarus_db'
    )
#get info from html forms
cgi = CGI.new("html5")

#returns the top 10 books in the US (THIS IS NOT DONE)
def getTopBooksUS(bookData)
    return bookData.first(10)
end

#returns the top 10 books globally (THIS IS NOT DONE)
def getTopBooksGlobal(bookData)
    return bookData.first(20).last(10)
end

#returns top 10 books for user (if they are signed in) (THIS IS NOT DONE)
def getTopBooksUser(bookData, userId)

end

bookData = db.query("Select * from Books;")
topBooksUS = getTopBooksUS(bookData)
topBooksGlobal = getTopBooksGlobal(bookData)
puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Icarus</title>"
puts "        <link rel=\"stylesheet\" href=\"Icarus.css\">"
puts "    </head>"
puts "    <body>"
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=\"#top-books\">Top Books</a></li>"
puts "                <li><a href=\"#search\">Search</a></li>"
puts "                <li><a href=\"#favorites\">Favorites</a></li>"
puts "                <li><a href=\"#reading-log\">Reading Log</a></li>"
puts "                <li><a href=\"#bts\">BTS</a></li>"
puts "                <li><a href=\"#sign-in\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
puts "        <h1>Top in US</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksUS.each do |book|
                        puts "            <a href=\"#\" class=\"image-item\">"
                        puts "                <img src=\"#{book['cover_image']}\" alt=\"#{book['title']}\">"
                        puts "            </a>"
                    end
puts "        </div>"
puts "        <h1>Top Global</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksGlobal.each do |book|
                        puts "            <a href=\"#\" class=\"image-item\">"
                        puts "                <img src=\"#{book['cover_image']}\" alt=\"#{book['title']}\">"
                        puts "            </a>"
                    end
puts "        </div>"
puts "    </body>"
puts "</html>"

