#!/usr/bin/ruby
#File: readingLog.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus

#   This is the reading log page for Icarus

$stdout.sync = true
$stderr.reopen $stdout

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'

require_relative '../env_loader'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

# get info from html forms
cgi = CGI.new("html5")
usrName = cgi['usrName']
removeFromLog = cgi['removeFromLog'] == 'true'
removeBookId = cgi['book_id']
searchQuery = cgi['searchQuery']

readingLogBooks = []

if usrName != ""
    user = db.query("SELECT usr_id FROM Users WHERE usr_name = '#{db.escape(usrName)}';").first
    if !user.nil?
        if removeFromLog
            db.query("DELETE FROM ReadingLog WHERE usr_id = #{user['usr_id'].to_i} AND book_id = #{removeBookId};")
        end

        if searchQuery == ''
            readingLogQuery = db.query("SELECT b.* FROM ReadingLog rl JOIN Books b ON rl.book_id = b.book_id WHERE rl.usr_id = #{user['usr_id'].to_i};")
        else
            searchLike = db.escape("%#{searchQuery}%")
            readingLogQuery = db.query("SELECT b.* FROM ReadingLog rl JOIN Books b ON rl.book_id = b.book_id WHERE rl.usr_id = #{user['usr_id'].to_i} AND (b.title LIKE '#{searchLike}');")
        end

        readingLogQuery.each do |book|
            readingLogBooks << book
        end
    end
end

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Reading Log</title>"
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
    puts "                <li><a href=\"readingLog.cgi\">Reading Log</a></li>"
    puts "                <li><a href=\"account.cgi\">Sign In</a></li>"
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
    puts "                    <form class=\"nav-post-form\" action=\"readingLog.cgi\" method=\"POST\">"
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
puts "        <h1>Reading Log</h1>"
puts "            <form action=\"readingLog.cgi\" method=\"POST\" class=\"search-form\">"
if usrName != ""
    puts "                <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
end
puts "                <input type=\"text\" name=\"searchQuery\" class=\"search-input\" maxlength=\"255\" placeholder=\"Search your reading log...\" value=\"#{CGI.escapeHTML(searchQuery)}\">"
puts "                <button type=\"submit\" class=\"search-button\">Search</button>"
puts "            </form>"

if usrName == ""
    puts "            <div class=\"book-notes\">"
    puts "                <p class=\"book-desc\">Please sign in to view your reading log.</p>"
    puts "            </div>"
elsif readingLogBooks.empty?
    puts "            <div class=\"book-notes\">"
        if searchQuery == ''
            puts "                <p class=\"book-desc\">No books in your reading log yet.</p>" 
        else
            puts "                <p class=\"book-desc\">No matching books found in your reading log.</p>"
        end
    puts "            </div>"
else
    puts "            <div class=\"search-results\">"
    readingLogBooks.each do |book|
        puts "                <div class=\"search-result-item\">"
        puts "                    <form action=\"book.cgi\" method=\"POST\">"
        puts "                        <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
        puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
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
        puts "                        <form class=\"signin-form book-note-form\" action=\"readingLog.cgi\" method=\"POST\">"
        puts "                            <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
        puts "                            <input type=\"hidden\" name=\"book_id\" value=\"#{book['book_id']}\">"
        puts "                            <input type=\"hidden\" name=\"removeFromLog\" value=\"true\">"
        puts "                            <input type=\"submit\" class=\"signin-submit\" value=\"Remove From Reading Log\">"
        puts "                        </form>"
        puts "                    </div>"
        puts "                </div>"
    end
puts "            </div>"
end

puts "        </div>"


puts "    </body>"
puts "</html>"
