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

# Google API to get the published date of the book.
def getBookPublishDate(title)
  uri = URI("https://www.googleapis.com/books/v1/volumes?q=#{title}")
  res = Net::HTTP.get_response(uri)
  data = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  publishDate = data.dig('items', 0, 'volumeInfo', 'publishedDate') if data
  return publishDate
end

# Put author(s) in Authors table and BookAuth table if they do not already exist
def fillAuthorTable(db, author, book_id)
    authorInDB = db.query("SELECT auth_id FROM Authors WHERE name = '" + author + "';")
    isAuthor = 0
    authorInDB.each do |a|
      isAuthor = a
    end

    if isAuthor == 0
      # Still need to get author description
      db.query("INSERT INTO Authors (name) VALUES('" + author + "');")
      authorID = db.query("SELECT auth_id FROM Authors WHERE name = '" + author + "';")
      authorID.each do |id|
        db.query("INSERT INTO BookAuth (book_id, auth_id) VALUES('" + book_id.to_s() + "', '" + id["auth_id"].to_s() + "');")
      end
    else
      db.query("INSERT INTO BookAuth (book_id, auth_id) VALUES('" + book_id.to_s() + "', '" + isAuthor["auth_id"].to_s() + "');")
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
    review = book["book_review_link"]
    langCode = "english"
    publishDate = getBookPublishDate(title)

    icarusDB.query("INSERT INTO Books (title, lang_code, isbn, publish_date, cover_img, review, description) VALUES('" + title + "', '" + langCode + "', '" + isbn.to_s() + "', '" + publishDate.to_s() + "', '" + coverImage + "', '" + review + "', '" + description + "');")
    bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
    bookID.each do |book|
        fillAuthorTable(icarusDB, author, book["book_id"])
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
    review = book["book_review_link"]
    langCode = "english"
    publishDate = getBookPublishDate(title)

    icarusDB.query("INSERT INTO Books (title, lang_code, isbn, publish_date, cover_img, review, description) VALUES('" + title + "', '" + langCode + "', '" + isbn.to_s() + "', '" + publishDate.to_s() + "', '" + coverImage + "', '" + review + "', '" + description + "');")
    bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
    bookID.each do |book|
        fillAuthorTable(icarusDB, author, book["book_id"])
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
    review = book["book_review_link"]
    langCode = "english"
    publishDate = getBookPublishDate(title)

    icarusDB.query("INSERT INTO Books (title, lang_code, isbn, publish_date, cover_img, review, description) VALUES('" + title + "', '" + langCode + "', '" + isbn.to_s() + "', '" + publishDate.to_s() + "', '" + coverImage + "', '" + review + "', '" + description + "');")
    bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
    bookID.each do |book|
        fillAuthorTable(icarusDB, author, book["book_id"])
    end
end

# Clear out the NewYorkBS table 
icarusDB.query("DELETE FROM NewYorkBS;")
populateNYTFiction(icarusDB)
sleep(120)
populateNYTNonFiction(icarusDB)
sleep(120)
populateNYTSelfHelp(icarusDB)