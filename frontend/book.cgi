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
require_relative '../backend/notes.rb'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

#get info from html forms
cgi = CGI.new("html5")
usrName = cgi['usrName'].to_s.strip
addingToLog = cgi['addingToLog'] == 'true' || cgi['addintToLog'] == 'true'
deleteLogEntry = cgi['deleteLogEntry'] == 'true'

bookId = cgi['book_id']
book = db.query("SELECT * FROM Books WHERE book_id = #{bookId};").first

# Get authors
authorIDs = db.query("SELECT auth_id FROM BookAuth WHERE book_id = #{bookId};")

#if User is signed in, get their notes for this book and display them on the page
notes = []
if usrName != ""
    userId = findUserId(usrName, db)
    if !userId.nil?
        notes = db.query("SELECT note, note_id FROM Notes WHERE usr_id = #{userId.to_i} AND book_id = #{bookId.to_i};")
    end
end

#check if usr is signed in and if the book is in the users reading log.
if usrName != "" && !userId.nil?
    readingLogEntry = db.query("SELECT * FROM ReadingLog WHERE usr_id = #{userId.to_i} AND book_id = #{bookId.to_i};").first
    inReadingLog = !readingLogEntry.nil?
end

def addReadingLogEntry(userId, bookId, db)
    db.query("INSERT INTO ReadingLog (usr_id, book_id) VALUES (#{userId.to_i}, #{bookId.to_i});")
end

def deleteReadingLogEntry(userId, bookId, db)
    db.query("DELETE FROM ReadingLog WHERE usr_id = #{userId.to_i} AND book_id = #{bookId.to_i};")
end

#if the user just added the book to their reading log, add it and then redirect back to the book page so that the "Add to Reading Log" button is replaced with a message saying it's in their reading log and so that the notes section appears
if addingToLog && !userId.nil?
    addReadingLogEntry(userId, bookId, db)
    puts "<!DOCTYPE html>"
    puts "<html>"
    puts "  <head>"
    puts "    <title>Redirecting...</title>"
    puts "  </head>"
    puts "  <body onload=\"document.getElementById('readingLogForm').submit();\">"
    puts "    <form id=\"readingLogForm\" method=\"post\" action=\"book.cgi\">"
    puts "      <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "       <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
    puts "    </form>"
    puts "    <noscript>"
    puts "      <button type=\"submit\" form=\"readingLogForm\">Continue to book page</button>"
    puts "    </noscript>"
    puts "  </body>"
    puts "</html>"
    exit
end

#if the user is signed in and wants to remove book from reading log this removes it and then reloads the page
if deleteLogEntry && !userId.nil?
    deleteReadingLogEntry(userId, bookId, db)
    puts "<!DOCTYPE html>"
    puts "<html>"
    puts "  <head>"
    puts "    <title>Redirecting...</title>"
    puts "  </head>"
    puts "  <body onload=\"document.getElementById('readingLogForm').submit();\">"
    puts "    <form id=\"readingLogForm\" method=\"post\" action=\"book.cgi\">"
    puts "      <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "       <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
    puts "    </form>"
    puts "    <noscript>"
    puts "      <button type=\"submit\" form=\"readingLogForm\">Continue to book page</button>"
    puts "    </noscript>"
    puts "  </body>"
    puts "</html>"
    exit
end

# a hidden form that auto submits after a note has been added
if cgi['note'] != ""
    createNote(userId, bookId, cgi['note'], db) if !userId.nil?
    puts "<!DOCTYPE html>"
    puts "<html>"
    puts "  <head>"
    puts "    <title>Redirecting...</title>"
    puts "  </head>"
    puts "  <body onload=\"document.getElementById('autoSubmitForm').submit();\">"
    puts "<form id=\"autoSubmitForm\" action=\"book.cgi\" method=\"POST\" style=\"display:none;\">"
    puts "    <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "    <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
    puts "</form>"
    puts "    <noscript>"
    puts "      <button type=\"submit\" form=\"autoSubmitForm\">Continue to book</button>"
    puts "    </noscript>"
    puts "  </body>"
    puts "</html>"
    exit
end

# a hidden form that auto submits after a note has been deleted
if cgi['delete_note_id'] != ""
    if !userId.nil?
        noteId = cgi['delete_note_id'].to_i
        noteToDelete = db.query("SELECT note_id FROM Notes WHERE note_id = #{noteId} AND usr_id = #{userId.to_i} AND book_id = #{bookId.to_i};").first
        deleteNote(noteToDelete['note_id'], db) if !noteToDelete.nil?
    end
    puts "<!DOCTYPE html>"
    puts "<html>"
    puts "  <head>"
    puts "    <title>Redirecting...</title>"
    puts "  </head>"
    puts "  <body onload=\"document.getElementById('autoSubmitForm').submit();\">"
    puts "<form id=\"autoSubmitForm\" action=\"book.cgi\" method=\"POST\" style=\"display:none;\">"
    puts "    <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "    <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
    puts "</form>"
    puts "    <noscript>"
    puts "      <button type=\"submit\" form=\"autoSubmitForm\">Continue to book</button>"
    puts "    </noscript>"
    puts "  </body>"
    puts "</html>"
    exit
end

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
if usrName == ""
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=../index.cgi>Top Books</a></li>"
puts "                <li><a href=\"../frontend/search.cgi\">Search</a></li>"
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
puts "                    <form class=\"nav-post-form\" action=\"../frontend/search.cgi\" method=\"POST\">"
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
                                authorIDs.each do |author|
                                authorDBQuery = db.query("SELECT auth_id, name FROM Authors WHERE auth_id = #{author["auth_id"]};").first
puts "                      <form action=\"author.cgi\" method=\"POST\" >"
puts "                          <input type=\"hidden\" name=\"auth_id\" value=#{authorDBQuery['auth_id']}>"
puts "                              <button type=\"submit\">"
if usrName != ""
puts "                                  <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
end
puts                                    "<a>#{authorDBQuery['name']} </a>"
puts "                              </button>"
puts "                      </form>"
                                end 
puts                      "</div>"
puts "                </div>"
puts "                <div class=\"book-right\">"
puts "                    <h1 class=\"book-title\">#{book['title']}</h1>"
puts "                    <div class=\"book-desc\">#{book['description']}"
if usrName != ""
    if inReadingLog
        puts "                      <form class=\"signin-form book-note-form\" action=\"book.cgi\" method=\"POST\">"
        puts "                          <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
        puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
        puts "                          <input type=\"hidden\" name=\"deleteLogEntry\" value=\"true\">"
        puts "                          <input type=\"submit\" class=\"signin-submit\" value=\"Remove From Reading Log\">"
        puts "                      </form>"
    else
        puts "                      <form class=\"signin-form book-note-form\" action=\"book.cgi\" method=\"POST\">"
        puts "                          <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
        puts "                          <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
        puts "                          <input type=\"hidden\" name=\"addingToLog\" value=\"true\">"
        puts "                          <input type=\"submit\" class=\"signin-submit\" value=\"Add To Reading Log\">"
        puts "                      </form>"
    end
end
puts "                    </div>"
puts "                    <h1 class=\"logo\">Borrow Or Buy</h1>"
puts "                    <div class=\"book-buy-borrow-list\">"
puts "                        <p><a class=\"book-buy-borrow\" href=\"https://www.amazon.com/s?k=#{book['isbn']}\" target=\"_blank\">Amazon</a></p>"
puts "                        <p><a class=\"book-buy-borrow\" href=\"https://www.worldcat.org/search?q=#{book['isbn']}\" target=\"_blank\">Library</a></p>"
puts "                    </div>"
puts "                    <h1 class=\"logo\">Notes</h1>"
if usrName != ""
    puts "                    <div class=\"book-notes\">"
    puts "                        <form class=\"signin-form book-note-form\" action=\"book.cgi\" method=\"POST\">"
    puts "                            <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                            <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
    puts "                            <label for=\"note\">Add Note:</label>"
    puts "                            <textarea id=\"note\" name=\"note\" rows=\"8\" maxlength=\"1000\" required></textarea>"
    puts "                            <input type=\"submit\" class=\"signin-submit\" value=\"Save Note\">"
    puts "                        </form>"
    notes.each do |note|
        puts "                        <div class=\"book-note-item\">"
        puts "                            <p>#{note['note'].gsub(/\r\n/, "<br>").gsub(/\n/, "<br>")}</p>"
        puts "                            <form class=\"book-note-delete-form\" action=\"book.cgi\" method=\"POST\">"
        puts "                                <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
        puts "                                <input type=\"hidden\" name=\"book_id\" value=\"#{bookId}\">"
        puts "                                <input type=\"hidden\" name=\"delete_note_id\" value=\"#{note['note_id']}\">"
        puts "                                <button type=\"submit\" class=\"book-note-delete\" aria-label=\"Delete note\">Delete</button>"
        puts "                            </form>"
        puts "                        </div>"
    end
    puts "                    </div>"
else 
    puts "                    <div class=\"book-notes\">"
    puts "                        <p class=\"book-desc\">Please sign in to view notes and add books to reading log.</p>"
    puts "                    </div>"
end
puts "                </div>"
puts "            </div>"
puts "        </div>"
puts "    </body>"
puts "</html>"  