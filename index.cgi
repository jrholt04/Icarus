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

usrName = cgi['usrName'].to_s.strip

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
if usrName == ""
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=index.cgi>Top Books</a></li>"
puts "                <li><a href=\"frontend/search.cgi\">Search</a></li>"
puts "                <li><a href=\"frontend/readingLog.cgi\">Reading Log</a></li>"
puts "                <li><a href=\"frontend/account.cgi\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
else
puts "        <nav>"
puts "            <nav><form class=\"nav-post-form\" action=\"index.cgi\" method=\"POST\"><input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\"><button type=\"submit\" class=\"nav-logo-button\">Icarus</button></form></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"index.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Top Books</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"frontend/search.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Search</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"frontend/readingLog.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Reading Log</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"frontend/account.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">#{CGI.escapeHTML(usrName)}</button>"
puts "                    </form>"
puts "                </li>"
puts "            </ul>"
puts "        </nav>"
end
puts "        <h1>Top Non Fiction This Week</h1>"
puts "        <div class=\"carousel-wrapper\">"
                    nonficBooks = topBooksNonFic.to_a
                    nonficPages = (nonficBooks.size / 5.0).ceil
                    nonficBooks.each_slice(5).with_index do |booksChunk, idx|
                        sectionId = "nonfic-page#{idx + 1}"
                        prevId = idx == 0 ? "nonfic-page#{nonficPages}" : "nonfic-page#{idx}"
                        nextId = idx == nonficPages - 1 ? "nonfic-page1" : "nonfic-page#{idx + 2}"
puts "            <section id=\"#{sectionId}\" class=\"carousel-section\">"
puts "                <a href=\"##{prevId}\" class=\"arrow-btn left-arrow\">&#8249;</a>"
puts "                <div class=\"scroll-container\">"
                        booksChunk.each do |book|
                            img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
                                if usrName != ""
puts "                              <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
                                end
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                        end
puts "                </div>"
puts "                <a href=\"##{nextId}\" class=\"arrow-btn right-arrow\">&#8250;</a>"
puts "            </section>"
                    end
puts "        </div>"
puts "        <h1>Top Fiction This Week</h1>"
puts "        <div class=\"carousel-wrapper\">"
                    ficBooks = topBooksFic.to_a
                    ficPages = (ficBooks.size / 5.0).ceil
                    ficBooks.each_slice(5).with_index do |booksChunk, idx|
                        sectionId = "fic-page#{idx + 1}"
                        prevId = idx == 0 ? "fic-page#{ficPages}" : "fic-page#{idx}"
                        nextId = idx == ficPages - 1 ? "fic-page1" : "fic-page#{idx + 2}"
puts "            <section id=\"#{sectionId}\" class=\"carousel-section\">"
puts "                <a href=\"##{prevId}\" class=\"arrow-btn left-arrow\">&#8249;</a>"
puts "                <div class=\"scroll-container\">"
                        booksChunk.each do |book|
                            img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
                                if usrName != ""
puts "                              <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
                                end
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                        end
puts "                </div>"
puts "                <a href=\"##{nextId}\" class=\"arrow-btn right-arrow\">&#8250;</a>"
puts "            </section>"
                    end
puts "        </div>"
puts "        <h1>Top Self Help This Week</h1>"
puts "        <div class=\"carousel-wrapper\">"
                    selfhelpBooks = topBooksSelfHelp.to_a
                    selfhelpPages = (selfhelpBooks.size / 5.0).ceil
                    selfhelpBooks.each_slice(5).with_index do |booksChunk, idx|
                        sectionId = "selfhelp-page#{idx + 1}"
                        prevId = idx == 0 ? "selfhelp-page#{selfhelpPages}" : "selfhelp-page#{idx}"
                        nextId = idx == selfhelpPages - 1 ? "selfhelp-page1" : "selfhelp-page#{idx + 2}"
puts "            <section id=\"#{sectionId}\" class=\"carousel-section\">"
puts "                <a href=\"##{prevId}\" class=\"arrow-btn left-arrow\">&#8249;</a>"
puts "                <div class=\"scroll-container\">"
                        booksChunk.each do |book|
                            img = book['cover_img']
puts "                      <form action=\"frontend/book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
                                if usrName != ""
puts "                              <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
                                end
puts "                              <button type=\"submit\" class=\"image-button\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                        end
puts "                </div>"
puts "                <a href=\"##{nextId}\" class=\"arrow-btn right-arrow\">&#8250;</a>"
puts "            </section>"
                    end
puts "        </div>"
puts "    </body>"
puts "</html>"

