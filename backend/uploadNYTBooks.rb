#!/usr/bin/ruby

# FILE: uploadNYTBooks.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to add books from the NYT Bestseller lists to the Icarus database tables

# NOTE: Does not check whether the books are already in the database

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

icarusDB = Mysql2::Client.new(:host => '10.20.3.4', :username => 'Icarus', :password => 'B00kz!', :database => 'ss_icarus_db')

def populateNYTFiction(db)
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

    for book in books do
        db.query("INSERT INTO NewYorkBS (book_id, category) VALUES (#{book['book_id']}, 'Fiction');")
    end
end 

def populateNYTNonFiction(db)
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

    for book in books do
        db.query("INSERT INTO NewYorkBS (book_id, category) VALUES (#{book['book_id']}, 'Non-Fiction');")
    end
end 

def populateNYTSelfHelp(db)
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
    
    for book in books do
        db.query("INSERT INTO NewYorkBS (book_id, category) VALUES (#{book['book_id']}, 'Self-Help');")
    end
end

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

    icarusDB.query("INSERT INTO Books (title, author, lang_code, isbn, cover_img, description) VALUES('" + title + "', '" + author + "', '" + langCode + "', '" + isbn.to_s() + "', '" + coverImage + "', '" + description + "');")
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

    icarusDB.query("INSERT INTO Books (title, author, lang_code, isbn, cover_img, description) VALUES('" + title + "', '" + author + "', '" + langCode + "', '" + isbn.to_s() + "', '" + coverImage + "', '" + description + "');")
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

    icarusDB.query("INSERT INTO Books (title, author, lang_code, isbn, cover_img, description) VALUES('" + title + "', '" + author + "', '" + langCode + "', '" + isbn.to_s() + "', '" + coverImage + "', '" + description + "');")
end

# Clear out the NewYorkBS table 
icarusDB.query("DELETE FROM NewYorkBS;")
populateNYTFiction(icarusDB)
populateNYTNonFiction(icarusDB)
populateNYTSelfHelp(icarusDB)