#!/usr/bin/ruby

# FILE: uploadNYTBooks.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to add books from the NYT Bestseller lists to the Icarus database tables
# Also sets up a table to hold the books from each bestseller list

# NOTE: Does not check whether the books are already in the database

$stdout.sync = true
$stderr.reopen $stdout

puts "Content-type: text/html\r\n\r\n" 

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

icarusDB = Mysql2::Client.new(:host => '10.20.3.4', :username => 'Icarus', :password => 'B00kz!', :database => 'ss_icarus_db')

# Delete and recreate table to hold the NYT Bestselling books
icarusDB.query("DROP TABLE NYTBooks;")
icarusDB.query(
    "CREATE TABLE NYTBooks (
    book_id INT PRIMARY KEY,
    nyt_list ENUM('nonfiction', 'fiction', 'how-to'),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
    );")

uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-nonfiction.json?api-key=klviqNxHeAn1sJLagvrTmACJIaYZ6aPRLv6hMCABttZcAcuF")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
nonFicBooks = data.dig("results", "books")

nonFicBooks.each() do |book|
    title = book["title"].gsub("'", "\\\\'")
    author = book["author"]
    isbn = book["primary_isbn13"]
    coverImage = book["book_image"]
    description = book["description"]
    langCode = "english"

    #icarusDB.query("INSERT INTO Books (title, author, lang_code, isbn, cover_img, description) VALUES('" + title + "', '" + author + "', '" + langCode + "', '" + isbn.to_s() + "', '" + coverImage + "', '" + description + "');")
    bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = " + isbn + ";")
    bookID.each do |id|
        icarusDB.query("INSERT INTO NYTBooks VALUES('" + id["book_id"].to_s() + "', 'nonfiction');")
    end
end

uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-fiction.json?api-key=klviqNxHeAn1sJLagvrTmACJIaYZ6aPRLv6hMCABttZcAcuF")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
fictionBooks = data.dig("results", "books")

fictionBooks.each() do |book|
    title = book["title"].gsub("'", "\\\\'")
    author = book["author"]
    isbn = book["primary_isbn13"]
    coverImage = book["book_image"]
    description = book["description"]
    langCode = "english"

    #icarusDB.query("INSERT INTO Books (title, author, lang_code, isbn, cover_img, description) VALUES('" + title + "', '" + author + "', '" + langCode + "', '" + isbn.to_s() + "', '" + coverImage + "', '" + description + "');")
    bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = " + isbn + ";")
    bookID.each do |id|
        icarusDB.query("INSERT INTO NYTBooks VALUES('" + id["book_id"].to_s() + "', 'fiction');")
    end
end

uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/advice-how-to-and-miscellaneous.json?api-key=klviqNxHeAn1sJLagvrTmACJIaYZ6aPRLv6hMCABttZcAcuF")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
howToBooks = data.dig("results", "books")

howToBooks.each() do |book|
    title = book["title"].gsub("'", "\\\\'")
    author = book["author"]
    isbn = book["primary_isbn13"]
    coverImage = book["book_image"]
    description = book["description"]
    langCode = "english"

    #icarusDB.query("INSERT INTO Books (title, author, lang_code, isbn, cover_img, description) VALUES('" + title + "', '" + author + "', '" + langCode + "', '" + isbn.to_s() + "', '" + coverImage + "', '" + description + "');")
    bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = " + isbn + ";")
    bookID.each do |id|
        icarusDB.query("INSERT INTO NYTBooks VALUES('" + id["book_id"].to_s() + "', 'how-to');")
    end
end
