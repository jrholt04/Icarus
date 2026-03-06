#!/usr/bin/ruby
#File: book.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   This is the author page for Icarus

$stdout.sync = true 
$stderr.reopen $stdout 

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'
require 'net/http'
require 'json'

require_relative '../env_loader'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

#get info from html forms
cgi = CGI.new("html5")

sort = cgi['sort'] || 'title'

authId = cgi['auth_id'] 

author = db.query("SELECT * FROM Authors WHERE auth_id = #{authId};").first

headshot = author && author['headshot']
headshotUrl = headshot.nil? || headshot.strip.empty? ? '../defaultAuth.png' : headshot

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
puts "                <li><a href=\"#sign-in\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
puts "        <main class=\"author-page\">"
puts "            <div class=\"author-left\">"
puts "                <img class=\"author-photo\" alt=\"Author photo\" src=\"#{headshotUrl}\">"
puts "            </div>"
puts "            <div class=\"author-right\">"
puts "                <h1 class=\"author-titles\">#{author['name']}</h1>"
puts "                <div class=\"author-section\">"
puts "                    <p class=\"author-bio\">#{author['bio']}</p>"
puts "                </div>"
puts "                <h1 class=\"author-titles\">Published Books</h1>"
puts "                <div class=\"author-sort-links\">"
puts "                    <form action=\"author.cgi\" method=\"POST\" class=\"author-sort-form\">"
puts "                        <input type=\"hidden\" name=\"auth_id\" value=\"#{authId}\">"
puts "                        <input type=\"hidden\" name=\"sort\" value=\"title\">"
puts "                        <button type=\"submit\" class=\"author-sort-button\">A-Z</button>"
puts "                    </form>"
puts "                    <form action=\"author.cgi\" method=\"POST\" class=\"author-sort-form\">"
puts "                        <input type=\"hidden\" name=\"auth_id\" value=\"#{authId}\">"
puts "                        <input type=\"hidden\" name=\"sort\" value=\"pub_date\">"
puts "                        <button type=\"submit\" class=\"author-sort-button\">Publication Date</button>"
puts "                    </form>"
puts "                </div>"
puts "                <div class=\"author-books\">"
                        if sort == 'pub_date'
                            books = db.query("SELECT b.*
                                        FROM BookAuth ba
                                        JOIN Books b ON b.book_id = ba.book_id
                                        WHERE ba.auth_id = #{authId}
                                        ORDER BY b.publish_date DESC;")
                        else 
                            books = db.query("SELECT b.*
                                    FROM BookAuth ba
                                    JOIN Books b ON b.book_id = ba.book_id
                                    WHERE ba.auth_id = #{authId}
                                    ORDER BY b.title ASC;")
                        end
                        books.each do |book|
                            img = book['cover_img']
puts "                      <form action=\"book.cgi\" method=\"POST\" class=\"image-item-form\">"
puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
puts "                              <button type=\"submit\" class=\"image-button-author\">"
puts "                                  <img src=\"#{img}\" alt=\"#{book['title']}\">"
puts "                              </button>"
puts "                      </form>"
                        end
puts "                </div>"
puts "            </div>"
puts "        </main>"
puts "    </body>"
puts "</html>"  