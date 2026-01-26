#!/usr/bin/ruby
#File: book.cgi
#Azalea Fylnn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   This is the book page for Icarus

$stdout.sync = true 
$stderr.reopen $stdout 

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'
require 'stringio'
require 'net/http'
require 'json'

db = Mysql2::Client.new(
    :host=>'10.20.3.4',
    :username=>'Icarus',
    :password=>'B00kz!',
    :database=>'ss_icarus_db'
    )

#this is the google api to get the desciription of the book.
def getTopBooksDescritption(book)
    uri = URI("https://www.googleapis.com/books/v1/volumes?q=#{book['title']}")
    res = Net::HTTP.get_response(uri)
    data = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
    description = data.dig('items', 0, 'volumeInfo', 'description') if data
    return description
end 

#get info from html forms
cgi = CGI.new("html5")

bookId = cgi['book_id']
book = db.query("SELECT * FROM Books WHERE book_id = #{bookId};").first
description = getTopBooksDescritption(book)

if book.nil?
    puts "Content-type: text/html\n\n"
    puts "<!DOCTYPE html>"
    puts "<html><body><h1>Book not found</h1></body></html>"
    exit
end

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
puts "        <div class=\"book-page-container\">"
puts "            <div class=\"book-info\">"
puts "                <div class=\"book-left\">"
puts "                    <img src=\"#{book['cover_img']}\" alt=\"#{book['title']}\">"
                            if book['isbn'] == '9999999999999' # checks if isbn is placeholder
                                puts "<div class=\"book-isbn\">isbn: N/A</div>"
                            else
                                puts "<div class=\"book-isbn\">isbn: #{book['isbn']}</div>"
                            end
puts "                    <div class=\"book-author\">by #{book['author']}</div>"
puts "                </div>"
puts "                <div class=\"book-right\">"
puts "                    <h1 class=\"book-title\">#{book['title']}</h1>"
puts "                    <div class=\"book-desc\">#{description}</div>"
puts "                    <h1 class=\"logo\">Reviews</h1>"
puts "                    <div class=\"book-desc\">#{book['rating']}/5</div>"
puts "                    <h1 class=\"logo\">Borrow Or Buy</h1>"
puts "                    <div class=\"book-desc\">Amazon: <a href=\"https://www.amazon.com/s?k=#{book['title']}\">#{book['title']}</a></div>"
puts "                    <div class=\"book-desc\">Library: <a href=\"https://www.worldcat.org/search?q=#{book['title']}\">#{book['title']}</a></div>"
puts "                    <h1 class=\"logo\">Notes</h1>"
puts "                </div>"
puts "            </div>"
puts "        </div>"
puts "    </body>"
puts "</html>"  