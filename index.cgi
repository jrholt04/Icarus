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

db = Mysql2::Client.new(
    :host=>'10.20.3.4',
    :username=>'Icarus',
    :password=>'B00kz!',
    :database=>'ss_icarus_db'
    )
#get info from html forms
cgi = CGI.new("html5")

#returns the top 15 fiction books from the new york times best sellers list
def getTopFic(db)
    uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-fiction.json?api-key=klviqNxHeAn1sJLagvrTmACJIaYZ6aPRLv6hMCABttZcAcuF")
    res = Net::HTTP.get_response(uri)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)
    ficBooks = data.dig("results", "books")

    titles = "("
    ficBooks.each do |b|
        titles += "'#{b['title'].gsub("'", "''")}',"
    end
    titles.chomp!(',')
    titles += ")"

    books = db.query("SELECT * FROM Books WHERE UPPER(title) IN #{titles};")

    return books
end

#returns the top 15 nonfiction books from the NYT best sellers list
def getTopNonFic(db)
    uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-nonfiction.json?api-key=klviqNxHeAn1sJLagvrTmACJIaYZ6aPRLv6hMCABttZcAcuF")
    res = Net::HTTP.get_response(uri)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)
    nonFicBooks = data.dig("results", "books")

    titles = "("
    nonFicBooks.each do |b|
        titles += "'#{b['title'].gsub("'", "''")}',"
    end
    titles.chomp!(',')
    titles += ")"

    books = db.query("SELECT * FROM Books WHERE UPPER(title) IN #{titles};")

    return books
end

#returns the top 15 self help books from the NYT best sellers list
def getTopSelfHelp(db)
    uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/advice-how-to-and-miscellaneous.json?api-key=klviqNxHeAn1sJLagvrTmACJIaYZ6aPRLv6hMCABttZcAcuF")
    res = Net::HTTP.get_response(uri)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)
    selfHelpBooks = data.dig("results", "books")

    titles = "("
    selfHelpBooks.each do |b|
        titles += "'#{b['title'].gsub("'", "''")}',"
    end
    titles.chomp!(',')
    titles += ")"
    
    books = db.query("SELECT * FROM Books WHERE UPPER(title) IN #{titles};")

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
puts "        <h1>Top Non Fiction</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksNonFic.each do |book|
                        img = book['cover_img']
                        puts "            <a href=\"frontend/book.cgi?book_id=#{book['book_id']}\" class=\"image-item\">"
                        puts "                <img src=#{img} alt=\"#{book['title']}\">"
                        puts "            </a>"
                    end
puts "        </div>"
puts "        <h1>Top Fiction</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksFic.each do |book|
                        img = book['cover_img']
                        puts "            <a href=\"frontend/book.cgi?book_id=#{book['book_id']}\" class=\"image-item\">"
                        puts "                <img src=#{img} alt=\"#{book['title']}\">"
                        puts "            </a>"
                    end
puts "        </div>"
puts "        <h1>Top Self Help</h1>"
puts "        <div class=\"scroll-container\">"
                    topBooksSelfHelp.each do |book|
                        img = book['cover_img']
                        puts "            <a href=\"frontend/book.cgi?book_id=#{book['book_id']}\" class=\"image-item\">"
                        puts "                <img src=#{img} alt=\"#{book['title']}\">"
                        puts "            </a>"
                    end
puts "        </div>"
puts "    </body>"
puts "</html>"

