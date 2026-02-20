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
require 'net/http'
require 'json'

require_relative 'env_loader'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

#get info from html forms
cgi = CGI.new("html5")

#returns the top 15 fiction books from the new york times best sellers list
def getTopFic(db)
   books = db.query("
        SELECT b.*
        FROM Books b
        JOIN NewYorkBS n ON b.book_id = n.book_id
        WHERE n.category = 'Fiction';")
    return books
end

#returns the top 15 nonfiction books from the NYT best sellers list
def getTopNonFic(db)
    books = db.query("
        SELECT b.*
        FROM Books b
        JOIN NewYorkBS n ON b.book_id = n.book_id
        WHERE n.category = 'Non-Fiction';")

    return books
end

#returns the top 15 self help books from the NYT best sellers list
def getTopSelfHelp(db)
    books = db.query("
        SELECT b.*
        FROM Books b
        JOIN NewYorkBS n ON b.book_id = n.book_id
        WHERE n.category = 'Self-Help';")
    return books
end

#returns top 10 books for user (if they are signed in) (THIS IS NOT DONE)
def getTopBooksUser(bookData, userId)

end


topBooksFic= getTopFic(db)
topBooksNonFic = getTopNonFic(db)
topBooksSelfHelp = getTopSelfHelp(db)
puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Icarus</title>"
puts "        <link rel=\"icon\" type=\"image/x-icon\" href=\"./favicon.ico\" id=\"favicon\" />"
puts "        <link rel=\"stylesheet\" href=\"Icarus.css\">"
puts "        <script>"
puts "            function updateFavicon() {"
puts "                const favicon = document.getElementById('favicon');"
puts "                const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;"
puts "                favicon.href = isDark ? './faviconwhite.ico' : './favicon.ico';"
puts "            }"
puts "            updateFavicon();"
puts "            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateFavicon);"
puts "        </script>"
puts "    </head>"
puts "    <body>"
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=index.cgi>Top Books</a></li>"
puts "                <li><a href=\"#search\">Search</a></li>"
puts "                <li><a href=\"#favorites\">Favorites</a></li>"
puts "                <li><a href=\"#reading-log\">Reading Log</a></li>"
puts "                <li><a href=\"#bts\">BTS</a></li>"
puts "                <li><a href=\"#sign-in\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
puts "        <h1>Top Non Fiction This Week</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksNonFic.each do |book|
                        img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                    end
puts "        </div>"
puts "        <h1>Top Fiction This Week</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksFic.each do |book|
                        img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                    end
puts "        </div>"
puts "        <h1>Top Self Help This Week</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksSelfHelp.each do |book|
                        img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                    end
puts "        </div>"
puts "    </body>"
puts "</html>"

