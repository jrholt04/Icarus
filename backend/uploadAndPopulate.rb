#!/usr/bin/ruby

# FILE: uploadAndPopulate.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to create and populate Icarus tables from a CSV file submitted through the arguments

# Arguments: filename
# CSV structure: header, columns separated by comma
# CSV column order: bookID, title, authors, average_rating, isbn, isbn13, language_code, num_pages, ratings_count, text_reviews_count, publication_date, publisher

$stdout.sync = true
$stderr.reopen $stdout

puts "Content-type: text/html\r\n\r\n" 

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

massInsertDB = Mysql2::Client.new(:host => '10.20.3.4', :username => 'Icarus', :password => 'B00kz!', :database => 'ss_icarus_db')

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

# Need to figure out whether the tables exist before deleting them
# Delete tables
massInsertDB.query("DROP TABLE FavAuthors;")
massInsertDB.query("DROP TABLE ReadingLog;")
massInsertDB.query("DROP TABLE Wishlist;")
massInsertDB.query("DROP TABLE BookAuth;")
massInsertDB.query("DROP TABLE Books;")
massInsertDB.query("DROP TABLE Authors;")

# Create tables
massInsertDB.query(
  "CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    lang_code CHAR(30) NOT NULL,
    isbn CHAR(30),
    pg_nums INT,
    cover_img VARCHAR(255),
    rating FLOAT,
    description VARCHAR(5000)
  );")

massInsertDB.query(
  "CREATE TABLE Authors (
    auth_id INT PRIMARY KEY AUTO_INCREMENT,
    fname VARCHAR(100),
    lname VARCHAR(100) NOT NULL,
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

# CSV column order: "bookId","title","series","author","rating","description","language","isbn","genres","characters","bookFormat","edition","pages","publisher","publishDate","firstPublishDate","awards","numRatings","ratingsByStars","likedPercent","setting","coverImg","bbeScore","bbeVotes","price"
# Authors currently in Books table, will need to move
booksFile.each do |book|
  splitBookRow = book.split("\",\"")
  title = splitBookRow[1].strip().gsub("'", "\\\\'")
  allAuthors = splitBookRow[3].strip()
  rating = splitBookRow[4].strip().to_f()
  lang_code = splitBookRow[6].strip()
  isbn = splitBookRow[7].strip().to_i()
  pg_nums = splitBookRow[12].strip().to_i()
  cover_img = splitBookRow[21].strip()

=begin
  authors = allAuthors.split("/")
  authors.each do |author|
    authorSplit = author.split(" ")
    # Figure out the first and last names of the author
    # What if an author does not have exactly 2 names?
  end
=end

  description = getTopBooksDescription(title)
  if description != nil
    description = description.gsub("'", "\\\\'")
    description = description.gsub('"', '\\\\"')
  else
    description = "No description given."
  end

  if (title == "")
    puts "ERROR: Missing book title"
    title = "MISSING BOOK TITLE"
  end
  if (isbn == 0)
    puts "ERROR: Missing ISBN"
    isbn = 9999999999999
  end

  massInsertDB.query("INSERT INTO Books (title, author, lang_code, isbn, pg_nums, cover_img, rating, description) VALUES('" + title + "', '" + allAuthors + "', '" + lang_code + "', '" + isbn.to_s() + "', '" + pg_nums.to_s() + "', '" + cover_img + "', '" + rating.to_s() + "', '" + description + "');")
end
