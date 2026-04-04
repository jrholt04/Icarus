#!/usr/bin/ruby
#File: search.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   This is the search page for Icarus

$stdout.sync = true 
$stderr.reopen $stdout 

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'
require_relative '../backend/search'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

#get info from html forms
cgi = CGI.new("html5")
usrName = cgi['usrName'].to_s.strip

searchResponse = cgi['searchType']
searchType = searchResponse == '' ? 'books' : searchResponse
searchQuery = cgi['searchQuery'] || ''
searchResults = []
searchPlaceholder = searchType == 'books' ? 'Search for books...' : 'Search for authors...'


if searchQuery && !searchQuery.strip.empty?
  if searchType == 'authors'
    searchResults = findAuthors(db, searchQuery).to_a
  else
    searchResults = findBooks(db, searchQuery).to_a
  end
end

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Search</title>"
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
if usrName == ""
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=../index.cgi>Top Books</a></li>"
puts "                <li><a href=\"search.cgi\">Search</a></li>"
puts "                <li><a href=\"../frontend/readingLog.cgi\">Reading Log</a></li>"
puts "                <li><a href=\"signIn.cgi\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
else
puts "        <nav>"
puts "            <nav><form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\"><input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\"><button type=\"submit\" class=\"nav-logo-button\">Icarus</button></form></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Top Books</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"search.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Search</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"../frontend/readingLog.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Reading Log</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"account.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">#{CGI.escapeHTML(usrName)}</button>"
puts "                    </form>"
puts "                </li>"
puts "            </ul>"
puts "        </nav>"
end
puts "        <div class=\"search-container\">"
puts "            <form action=\"search.cgi\" method=\"POST\" class=\"search-form\">"
puts "                <input type=\"hidden\" name=\"searchType\" value=\"#{searchType}\">"
if usrName != ""
puts "                    <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
end
puts "                <input type=\"text\" name=\"searchQuery\" class=\"search-input\" maxlength=\"255\" placeholder=\"#{searchPlaceholder}\" value=\"#{searchQuery}\">"
puts "                <button type=\"submit\" class=\"search-button\">Search</button>"
puts "            </form>"
puts "            <div class=\"search-mode-links\">"
puts "                <form action=\"search.cgi\" method=\"POST\" class=\"search-mode-form\">"
puts "                    <input type=\"hidden\" name=\"searchType\" value=\"books\">"
puts "                    <input type=\"hidden\" name=\"searchQuery\" value=\"#{searchQuery}\">"
if usrName != ""
puts "                    <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
end
puts "                    <button type=\"submit\" class=\"search-mode-link#{searchType == 'books' ? ' active' : ''}\">Books</button>"
puts "                </form>"
puts "                <form action=\"search.cgi\" method=\"POST\" class=\"search-mode-form\">"
puts "                    <input type=\"hidden\" name=\"searchType\" value=\"authors\">"
puts "                    <input type=\"hidden\" name=\"searchQuery\" value=\"#{searchQuery}\">"
if usrName != ""
puts "                    <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
end
puts "                    <button type=\"submit\" class=\"search-mode-link#{searchType == 'authors' ? ' active' : ''}\">Authors</button>"
puts "                </form>"
puts "            </div>"

if searchQuery
    puts "            <div class=\"search-results\">"
  if searchType == 'authors'
    searchResults.each do |authorRecord|
      headshotUrl = authorRecord['headshot'] && !authorRecord['headshot'].strip.empty? ? authorRecord['headshot'] : '../defaultAuth.png'
      puts "                <div class=\"search-result-item\">"
      puts "                    <form action=\"author.cgi\" method=\"POST\">"
      puts "                        <input type=\"hidden\" name=\"auth_id\" value=\"#{authorRecord['auth_id']}\">"
      if usrName != ""
        puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
      end
      puts "                        <button type=\"submit\" style=\"border: none; background: none; padding: 0; cursor: pointer;\">"
      puts "                            <img src=\"#{headshotUrl}\" alt=\"#{authorRecord['name']}\" class=\"search-result-image search-result-image-author\">"
      puts "                        </button>"
      puts "                    </form>"
      puts "                    <div class=\"search-result-content\">"
      puts "                        <div class=\"search-result-title search-result-title-author\">#{authorRecord['name']}</div>"
      puts "                        <div class=\"search-result-description\">#{authorRecord['bio'] || ''}</div>"
      puts "                    </div>"
      puts "                </div>"
    end
  else
    searchResults.each do |book|
      puts "                <div class=\"search-result-item\">"
      puts "                    <form action=\"book.cgi\" method=\"POST\">"
      puts "                        <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
      if usrName != ""
      puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
      end
      puts "                        <button type=\"submit\" style=\"border: none; background: none; padding: 0; cursor: pointer;\">"
      puts "                            <img src=\"#{book['cover_img']}\" alt=\"#{book['title']}\" class=\"search-result-image\">"
      puts "                        </button>"
      puts "                    </form>"
      puts "                    <div class=\"search-result-content\">"
      puts "                        <div class=\"search-result-title\">#{book['title']}</div>"
      
      authorIds = db.query("SELECT auth_id FROM BookAuth WHERE book_id = #{book['book_id']};")
      authors = []
      authorIds.each do |auth|
        author = db.query("SELECT name FROM Authors WHERE auth_id = #{auth['auth_id']};").first
        authors << author['name'] if author
      end
      
      if authors.length > 1
        puts "                        <div class=\"search-result-author\">by #{authors.join(', ')}</div>"
      end
      
      puts "                        <div class=\"search-result-description\">#{book['description'] || ''}</div>"
      puts "                    </div>"
      puts "                </div>"
    end
  end
  puts "            </div>"
end

puts "        </div>"
puts "    </body>"
puts "</html>"
