#!/usr/bin/ruby

# FILE: uploadAndPopulate.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to create and populate Icarus tables from a CSV file submitted through the arguments

# Arguments: filename
# CSV structure: header, columns separated by comma

$stdout.sync = true
$stderr.reopen $stdout

puts "Content-type: text/html\r\n\r\n" 

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'

massInsertDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

booksFile = IO.readlines(ARGV[0])

# Drop the header of the file
booksFile = booksFile.drop(1)

# Google API to get the description of the book.
def getTopBooksDescription(title)
  uri = URI("https://www.googleapis.com/books/v1/volumes?q=#{title}")
  res = Net::HTTP.get_response(uri)
  data = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  description = data.dig('items', 0, 'volumeInfo', 'description') if data
  return description
end 

# Google API to get the ISBN of the book.
def getBookISBN(title)
  uri = URI("https://www.googleapis.com/books/v1/volumes?q=#{title}")
  res = Net::HTTP.get_response(uri)
  data = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  isbn = data.dig('items', 0, 'volumeInfo', 'industryIdentifiers') if data
  puts isbn
  return isbn
end

# Put author(s) in Authors table and BookAuth table if they do not already exist
def fillAuthorTable(db, allAuthors, book_id)
  authors = allAuthors.split(",")
  authors.each do |author|
    authorSplit = author.split(" ")
    cleanAuthor = ""
    authorSplit.each do |name|
      if name[0] != "(" && name[name.length() - 1] != ")"
        cleanAuthor = cleanAuthor + name + " "
      end
    end
    cleanAuthor = cleanAuthor.strip()

    authorInDB = db.query("SELECT auth_id FROM Authors WHERE name = '" + cleanAuthor + "';")
    isAuthor = 0
    authorInDB.each do |a|
      isAuthor = a
    end

    if isAuthor == 0
      # Still need to get author description
      db.query("INSERT INTO Authors (name) VALUES('" + cleanAuthor + "');")
      authorID = db.query("SELECT auth_id FROM Authors WHERE name = '" + cleanAuthor + "';")
      authorID.each do |id|
        db.query("INSERT INTO BookAuth (book_id, auth_id) VALUES('" + book_id.to_s() + "', '" + id["auth_id"].to_s() + "');")
      end
    else
      db.query("INSERT INTO BookAuth (book_id, auth_id) VALUES('" + book_id.to_s() + "', '" + isAuthor["auth_id"].to_s() + "');")
    end
  end
end

# Need to figure out whether the tables exist before deleting them
# Delete tables
massInsertDB.query("DROP TABLE FavAuthors;")
massInsertDB.query("DROP TABLE ReadingLog;")
massInsertDB.query("DROP TABLE Wishlist;")
massInsertDB.query("DROP TABLE BookAuth;")
massInsertDB.query("DROP TABLE NewYorkBS;")
massInsertDB.query("DROP TABLE Books;")
massInsertDB.query("DROP TABLE Authors;")

# Create tables
massInsertDB.query(
  "CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    lang_code CHAR(30) NOT NULL,
    isbn CHAR(30),
    pg_nums INT,
    publish_date CHAR(30),
    cover_img VARCHAR(255),
    rating FLOAT,
    review VARCHAR(255),
    description VARCHAR(5000)
  );")

massInsertDB.query(
  "CREATE TABLE Authors (
    auth_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    bio VARCHAR(1000),
    headshot LONGBLOB
  );")

massInsertDB.query(
  "CREATE TABLE FavAuthors (
    usr_id INT NOT NULL,
    auth_id INT NOT NULL,
    PRIMARY KEY (usr_id, auth_id),
    FOREIGN KEY (usr_id) REFERENCES Users(usr_id),
    FOREIGN KEY (auth_id) REFERENCES Authors(auth_id)
  );")

massInsertDB.query(
  "CREATE TABLE ReadingLog (
    usr_id INT NOT NULL,
    book_id INT NOT NULL,
    notes VARCHAR(1000),
    PRIMARY KEY (usr_id, book_id),
    FOREIGN KEY (usr_id) REFERENCES Users(usr_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
  );")

massInsertDB.query(
  "CREATE TABLE Wishlist (
    usr_id INT NOT NULL,
    book_id INT NOT NULL,
    PRIMARY KEY (usr_id, book_id),
    FOREIGN KEY (usr_id) REFERENCES Users(usr_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
  );")

massInsertDB.query(
  "CREATE TABLE BookAuth (
   book_id INT NOT NULL,
   auth_id INT NOT NULL,
   PRIMARY KEY (auth_id, book_id),
   FOREIGN KEY (book_id) REFERENCES  Books(book_id),
   FOREIGN KEY (auth_id) REFERENCES Authors(auth_id) 
  );")

massInsertDB.query(
  "CREATE TABLE NewYorkBS (
  book_id INT,
  category VARCHAR(100),
  FOREIGN KEY (book_id) REFERENCES Books(book_id)
);")

# CSV column order: "bookId","title","series","author","rating","description","language","isbn","genres","characters","bookFormat","edition","pages","publisher","publishDate","firstPublishDate","awards","numRatings","ratingsByStars","likedPercent","setting","coverImg","bbeScore","bbeVotes","price"
# Authors currently in Books table, will need to move
bookID = 0
booksFile.each do |book|
  bookID = bookID + 1
  splitBookRow = book.split("\",\"")
  title = splitBookRow[1].strip().gsub("'", "\\\\'")
  allAuthors = splitBookRow[3].strip()
  rating = splitBookRow[4].strip().to_f()
  lang_code = splitBookRow[6].strip()
  isbn = splitBookRow[7].strip().to_i()
  pg_nums = splitBookRow[12].strip().to_i()
  cover_img = splitBookRow[21].strip()
  publish_date = splitBookRow[14].strip()

  description = getTopBooksDescription(title)
  if description != nil
    description = description.gsub("'", "\\\\'")
    description = description.gsub('"', '\\\\"')
  else
    description = "No description given."
  end

  #isbn = getBookISBN(title)

  if (title == "")
    puts "ERROR: Missing book title"
    title = "MISSING BOOK TITLE"
  end
  if (isbn == 0)
    puts "ERROR: Missing ISBN"
    isbn = 9999999999999
  end

  massInsertDB.query("INSERT INTO Books (title, lang_code, isbn, pg_nums, publish_date, cover_img, rating, description) VALUES('" + title + "', '" + lang_code + "', '" + isbn.to_s() + "', '" + pg_nums.to_s() + "', '" + publish_date + "', '" + cover_img + "', '" + rating.to_s() + "', '" + description + "');")
  fillAuthorTable(massInsertDB, allAuthors, bookID)
end
