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
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

#get info from html forms
cgi = CGI.new("html5")

bookId = cgi['book_id']
book = db.query("SELECT * FROM Books WHERE book_id = #{bookId};").first

# Get authors
authorIDs = db.query("SELECT auth_id FROM BookAuth WHERE book_id = #{bookId};")


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
puts "        <link rel=\"icon\" type=\"image/x-icon\" href=\"../favicon.ico\" id=\"favicon\" />"
puts "        <link rel=\"stylesheet\" href=\"../Icarus.css\">"
puts "        <script>"
puts "            function updateFavicon() {"
puts "                const favicon = document.getElementById('favicon');"
puts "                const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;"
puts "                favicon.href = isDark ? '../faviconwhite.ico' : '../favicon.ico';"
puts "            }"
puts "            updateFavicon();"
puts "            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateFavicon);"
puts "        </script>"
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
                                puts "<div class=\"book-isbn\">ISBN: N/A</div>"
                            else
                                puts "<div class=\"book-isbn\">ISBN: #{book['isbn']}</div>"
                            end
puts "                    <div class=\"book-author\">by " 
puts "                      <form action=\"author.cgi\" method=\"POST\" >"
                                authorIDs.each do |author|
puts "                          <input type=\"hidden\" name=\"auth_id\" value=#{author['auth_id']}>"
puts "                              <button type=\"submit\">"
                                    authorDBQuery = db.query("SELECT name FROM Authors WHERE auth_id = #{author["auth_id"]};").first
puts                                    "<a>#{authorDBQuery['name']} </a>"
puts "                              </button>"
                                end 
puts "                      </form>"
puts                      "</div>"
puts "                </div>"
puts "                <div class=\"book-right\">"
puts "                    <h1 class=\"book-title\">#{book['title']}</h1>"
puts "                    <div class=\"book-desc\">#{book['description']}</div>"
puts "                    <h1 class=\"logo\">Borrow Or Buy</h1>"
puts "                    <div class=\"book-buy-borrow-list\">"
puts "                        <p><a class=\"book-buy-borrow\" href=\"https://www.amazon.com/s?k=#{book['isbn']}\">Amazon</a></p>"
puts "                        <p><a class=\"book-buy-borrow\" href=\"https://www.worldcat.org/search?q=#{book['isbn']}\">Library</a></p>"
puts "                    </div>"
puts "                    <h1 class=\"logo\">Notes</h1>"
puts "                </div>"
puts "            </div>"
puts "        </div>"
puts "    </body>"
puts "</html>"  