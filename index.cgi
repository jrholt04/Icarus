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
puts "        <link rel=\"stylesheet\" href=\"Icarus.css\">"
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
puts "        <div class=\"scroll-wrapper\">"
puts "            <button class=\"scroll-btn scroll-left\" data-target=\"non-fic-scroll\" aria-label=\"Scroll left\">&#8249;</button>"
puts "            <div id=\"non-fic-scroll\" class=\"scroll-container\">"
                    topBooksNonFic.each do |book|
                        img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                    end
puts "            </div>"
puts "            <button class=\"scroll-btn scroll-right\" data-target=\"non-fic-scroll\" aria-label=\"Scroll right\">&#8250;</button>"
puts "        </div>"
puts "        <h1>Top Fiction This Week</h1>"
puts "        <div class=\"scroll-wrapper\">"
puts "            <button class=\"scroll-btn scroll-left\" data-target=\"fic-scroll\" aria-label=\"Scroll left\">&#8249;</button>"
puts "            <div id=\"fic-scroll\" class=\"scroll-container\">"
                    topBooksFic.each do |book|
                        img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                    end
puts "            </div>"
puts "            <button class=\"scroll-btn scroll-right\" data-target=\"fic-scroll\">&#8250;</button>"
puts "        </div>"
puts "        <h1>Top Self Help This Week</h1>"
puts "        <div class=\"scroll-wrapper\">"
puts "            <button class=\"scroll-btn scroll-left\" data-target=\"selfhelp-scroll\">&#8249;</button>"
puts "            <div id=\"selfhelp-scroll\" class=\"scroll-container\">"
                    topBooksSelfHelp.each do |book|
                        img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                    end
puts "            </div>"
puts "            <button class=\"scroll-btn scroll-right\" data-target=\"selfhelp-scroll\" aria-label=\"Scroll right\">&#8250;</button>"
puts "        </div>"
puts "<script>"
puts "  // Adapted from: https://stackoverflow.com/questions/74209391/how-can-i-make-a-nav-scrolling-horizontally-with-buttons-when-media-queries-kick"
puts "  document.querySelectorAll('.scroll-btn').forEach(function(btn) {"
puts "    btn.addEventListener('click', function() {"
puts "      var targetId = btn.getAttribute('data-target');"
puts "      var scroller = document.getElementById(targetId);"
puts "      if (!scroller) return;"
puts "      var direction = btn.classList.contains('scroll-right') ? 1 : -1;"
puts "      var amount = Math.max(260, Math.floor(scroller.clientWidth * 0.8));"
puts "      scroller.scrollBy({ left: direction * amount, behavior: 'smooth' });"
puts "    });"
puts "  });"
puts "</script>"
puts "    </body>"
puts "</html>"

