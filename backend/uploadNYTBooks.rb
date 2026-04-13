#!/usr/bin/ruby

# FILE: uploadNYTBooks.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to add books from the NYT Bestseller lists to the Icarus database tables

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'

NYT_API_KEY = ENV.fetch('NYT_API_KEY')

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

def populateNYTFiction(db)
    uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-fiction.json?api-key=#{NYT_API_KEY}")
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
    uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-nonfiction.json?api-key=#{NYT_API_KEY}")
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
    uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/advice-how-to-and-miscellaneous.json?api-key=#{NYT_API_KEY}")
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
  sleep(10)
  return publishDate
end

# Put author(s) in Authors table and BookAuth table if they do not already exist
def fillAuthorTable(db, author, bookId)
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
                db.query("INSERT IGNORE INTO BookAuth (book_id, auth_id) VALUES('" + bookId.to_s() + "', '" + id["auth_id"].to_s() + "');")
      end
    else
                db.query("INSERT IGNORE INTO BookAuth (book_id, auth_id) VALUES('" + bookId.to_s() + "', '" + isAuthor["auth_id"].to_s() + "');")
    end
end

def findExistingBookId(db, isbn)
    existing = db.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
    existing.each do |row|
        return row["book_id"]
    end
    nil
end

uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-nonfiction.json?api-key=#{NYT_API_KEY}")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
nonFicBooks = data.dig("results", "books")
sleep(10)

nonFicBooks.each() do |book|
    title = book["title"].gsub("'", "\\\\'")
    author = book["author"]
    isbn = book["primary_isbn13"]
    coverImage = book["book_image"]
    description = book["description"]
    review = book["book_review_link"]
    langCode = "english"

    # Check if the book is already in the table
    if !icarusDB.query("SELECT * FROM Books WHERE isbn = " + isbn.to_s() + ";").first().nil?
        next
    end

    publishDate = getBookPublishDate(title)

    icarusDB.query("INSERT INTO Books (title, lang_code, isbn, publish_date, cover_img, review, description) VALUES('" + title + "', '" + langCode + "', '" + isbn.to_s() + "', '" + publishDate.to_s() + "', '" + coverImage + "', '" + review + "', '" + description + "');")
    bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
    
    # Fill in the author's table, checking for multiple authors
    wordAnd = /\sand\s/
    wordWith = /\swith\s/
    bookID.each do |book|
        if wordAnd.match(author)
            authors = author.split(" and ")
            authors.each do |a|
                fillAuthorTable(icarusDB, a, book["book_id"])
            end
        elsif wordWith.match(author)
            authors = author.split(" with ")
            authors.each do |a|
                fillAuthorTable(icarusDB, a, book["book_id"])
            end
        else
            fillAuthorTable(icarusDB, author, book["book_id"])
        end
        existingBookId = findExistingBookId(icarusDB, isbn)
        if existingBookId
            fillAuthorTable(icarusDB, author, existingBookId)
        else
            icarusDB.query("INSERT INTO Books (title, lang_code, isbn, publish_date, cover_img, review, description) VALUES('" + title + "', '" + langCode + "', '" + isbn.to_s() + "', '" + publishDate.to_s() + "', '" + coverImage + "', '" + review + "', '" + description + "');")
            bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
            bookID.each do |book|
                fillAuthorTable(icarusDB, author, book["book_id"])
            end
        end
    end
end

uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-fiction.json?api-key=#{NYT_API_KEY}")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
fictionBooks = data.dig("results", "books")
sleep(10)

fictionBooks.each() do |book|
    title = book["title"].gsub("'", "\\\\'")
    author = book["author"]
    isbn = book["primary_isbn13"]
    coverImage = book["book_image"]
    description = book["description"]
    review = book["book_review_link"]
    langCode = "english"

    # Check if the book is already in the table
    if !icarusDB.query("SELECT * FROM Books WHERE isbn = " + isbn.to_s() + ";").first().nil?
        next
    end

    publishDate = getBookPublishDate(title)

    existingBookId = findExistingBookId(icarusDB, isbn)
    if existingBookId
        fillAuthorTable(icarusDB, author, existingBookId)
    else
        icarusDB.query("INSERT INTO Books (title, lang_code, isbn, publish_date, cover_img, review, description) VALUES('" + title + "', '" + langCode + "', '" + isbn.to_s() + "', '" + publishDate.to_s() + "', '" + coverImage + "', '" + review + "', '" + description + "');")
        bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
    
    # Fill in the author's table, checking for multiple authors
    wordAnd = /\sand\s/
    wordWith = /\swith\s/
    bookID.each do |book|
            if wordAnd.match(author)
            authors = author.split(" and ")
            authors.each do |a|
                fillAuthorTable(icarusDB, a, book["book_id"])
            end
        elsif wordWith.match(author)
            authors = author.split(" with ")
            authors.each do |a|
                fillAuthorTable(icarusDB, a, book["book_id"])
            end
        else
            fillAuthorTable(icarusDB, author, book["book_id"])
        end
        end
    end
end

uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/advice-how-to-and-miscellaneous.json?api-key=#{NYT_API_KEY}")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
howToBooks = data.dig("results", "books")
sleep(10)

howToBooks.each() do |book|
    title = book["title"].gsub("'", "\\\\'")
    author = book["author"]
    isbn = book["primary_isbn13"]
    coverImage = book["book_image"]
    description = book["description"]
    review = book["book_review_link"]
    langCode = "english"

    # Check if the book is already in the table
    if !icarusDB.query("SELECT * FROM Books WHERE isbn = " + isbn.to_s() + ";").first().nil?
        next
    end

    publishDate = getBookPublishDate(title)

    existingBookId = findExistingBookId(icarusDB, isbn)
    if existingBookId
        fillAuthorTable(icarusDB, author, existingBookId)
    else
        icarusDB.query("INSERT INTO Books (title, lang_code, isbn, publish_date, cover_img, review, description) VALUES('" + title + "', '" + langCode + "', '" + isbn.to_s() + "', '" + publishDate.to_s() + "', '" + coverImage + "', '" + review + "', '" + description + "');")
        bookID = icarusDB.query("SELECT book_id FROM Books WHERE isbn = '" + isbn.to_s() + "';")
    # Fill in the author's table, checking for multiple authors
        wordAnd = /\sand\s/
        wordWith = /\swith\s/
        bookID.each do |book|
            if wordAnd.match(author)
            authors = author.split(" and ")
                authors.each do |a|
                    fillAuthorTable(icarusDB, a, book["book_id"])
                end
            elsif wordWith.match(author)
                authors = author.split(" with ")
                authors.each do |a|
                    fillAuthorTable(icarusDB, a, book["book_id"])
                end
            else
                fillAuthorTable(icarusDB, author, book["book_id"])
            end
        end
    end
end

# Clear out the NewYorkBS table 
icarusDB.query("DELETE FROM NewYorkBS;")
sleep(120)
populateNYTFiction(icarusDB)
sleep(120)
populateNYTNonFiction(icarusDB)
sleep(120)
populateNYTSelfHelp(icarusDB)