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

massInsertDB = Mysql2::Client.new(:host => '10.20.3.4', :username => 'Icarus', :password => 'B00kz!', :database => 'ss_icarus_db')

booksFile = IO.readlines(ARGV[0])

# Drop the header of the file
booksFile = booksFile.drop(1)

=begin
massInsertCGI = CGI.new("html5") 
uploadLocation = "/NFSHome/ekendall/public_html/UploadAndPopulate/Uploads/"

# Ensures the given file can be opened properly regardless of whether this is the first time through this program
if (massInsertCGI['originalName'] == "")
  fromFile = massInsertCGI.params['fileName'].first
  originalName = massInsertCGI.params['fileName'].first.instance_variable_get("@original_filename")
  
  toFile = uploadLocation + originalName.to_s() 
  File.open(toFile.untaint, 'w') {|file| file << fromFile.read}
else
  originalName = massInsertCGI['originalName'].to_s()
  toFile = uploadLocation + originalName.to_s()
end

uploadedFile = IO.readlines(toFile)

allKeysInTable = true
keys = ""
if (massInsertCGI['originalName'] == "" and massInsertCGI['primaryKey'].to_s() != "")
  columnNames = uploadedFile[0].split(",")
  keys = massInsertCGI['primaryKey'].split(",")
  keys.each do |key|
    keyInTable = false
    columnNames.each do |attribute|
      attribute.strip()
      if (key.strip() == attribute.strip())
        keyInTable = true
      end
    end
    if (!keyInTable)
      allKeysInTable = false
    end
  end

  if (!allKeysInTable)
    puts "<!DOCTYPE html>"
    puts "<html lang=\"en\">"
    puts "<head>"
    puts "<title> Choose Keys </title>"
    puts "</head>"
    puts "<body>"
    puts "<h1> Choose Your Keys </h1>"
    puts "<form enctype=\"multipart/form-data\" action=\"massInsert.cgi\" method=\"post\">"
    puts "<legend> Which key(s) do you want to use? Leave blank to use a unique id instead. </legend>"
    puts "<input type=\"hidden\" id=\"originalName\" name=\"originalName\" value=\"" + originalName.to_s() + "\">"
    puts "<input type=\"hidden\" id=\"tableName\" name=\"tableName\" value=\"" + massInsertCGI['tableName'].to_s() + "\">"
    columnNames.each do |attribute|
      puts "<input type =\"checkbox\" name=\"primaryKey\" value=\"" + attribute.strip() + "\"> " + attribute.strip() + " <br>"
    end
    puts "<br>"
    puts "<input type=\"submit\" value=\"Submit Keys\">"
    puts "</form>"
    puts "</body>"
    puts "</html>"
  end
end
=end

# Change this to take in the name as args instead of HTML
# SHOW COLUMNS FROM table - shows how the table was created
=begin
validTableName = true
allTables = massInsertDB.query("SHOW TABLES;")
allTables.each do |table|
  if (table['Tables_in_dbms_ek_dbA'] == massInsertCGI['tableName'].to_s())
    validTableName = false
  end
end
=end

# Need to figure out whether the tables exist before deleting them
# For now use this query: drop table Authors, BookAuth, Books, FavAuthors, ReadingLog, Wishlist;
=begin
# Delete tables
massInsertDB.query("DROP TABLE FavAuthors;")
massInsertDB.query("DROP TABLE ReadingLog;")
massInsertDB.query("DROP TABLE Wishlist;")
massInsertDB.query("DROP TABLE BookAuth;")
massInsertDB.query("DROP TABLE Books;")
massInsertDB.query("DROP TABLE Authors;")
=end

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
    rating FLOAT
  );")

# Maybe we don't want to delete the users table every time we run this?
=begin
massInsertDB.query(
  "CREATE TABLE Users (
    usr_id INT PRIMARY KEY AUTO_INCREMENT,
    usr_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    pswd VARCHAR(255) NOT NULL
  );")
=end

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

=begin
if (!validTableName and allKeysInTable)
  puts "<!DOCTYPE html>"
  puts "<html lang=\"en\">"
  puts "<head>"
  puts "<title> Choose Table Name </title>"
  puts "</head>"
  puts "<body>"
  puts "<h1> Choose Your Table Name </h1>"
  puts "<form enctype=\"multipart/form-data\" action=\"massInsert.cgi\" method=\"post\">"
  puts "<legend> Sorry, the table name " + massInsertCGI['tableName'].to_s() + " already exists. Please choose a different one: </legend>"
  puts "<input type=\"hidden\" id=\"originalName\" name=\"originalName\" value=\"" + originalName.to_s() + "\">"
  if (massInsertCGI['primaryKey'].to_s() == "")
    puts "<input type=\"hidden\" id=\"primaryKey\" name=\"primaryKey\" value=\"\">"
  else
    massInsertCGI.params['primaryKey'].each do |key|
      puts "<input type=\"hidden\" id=\"primaryKey\" name=\"primaryKey\" value=\"" + key.strip().to_s() + "\">"
    end
  end
  puts "<input type =\"text\" name=\"tableName\" size=\"40\" required><br>"
  puts "<br>"
  puts "<input type=\"submit\" value=\"Submit Table Name\">"
  puts "</form>"
  puts "</body>"
  puts "</html>"
end
=end

# Change this to work with the file and not worry about the HTML
# Args done with argv
=begin
if (allKeysInTable and validTableName)
  puts "<!DOCTYPE html>"
  puts "<html lang=\"en\">" 
  puts "<head>" 
  puts "<meta http-equiv='refresh' content='20; url=index.html'>"
  puts "<title> Uploading File </title>" 
  puts "</head>" 
  puts "<body>"
  puts "<h1> Error Log: </h1>"

  sqlAttributes = "id int NOT NULL"
  columnNames = uploadedFile[0].split(",")
  columnNames.each do |attribute|
    sqlAttributes = sqlAttributes + ", " + attribute.strip().gsub(" ", "") + " varchar(100) NOT NULL"
  end

  if (massInsertCGI['originalName'] == "")
    keys = massInsertCGI['primaryKey'].split(",")
  else
    keys = massInsertCGI.params['primaryKey']
  end

  if (keys[0].to_s().strip() != "")
    keysString = keys[0].strip().gsub(" ", "")
    keys.drop(1).each do |key|
      keysString = keysString + ", " + key.strip().gsub(" ", "")
    end
  else
    keysString = "id"
  end

  tableCreated = true
  begin
    massInsertDB.query("CREATE TABLE " + massInsertCGI['tableName'].to_s() + "(" + sqlAttributes + ", PRIMARY KEY (" + keysString + "));")
  rescue => createError
    puts "<p> ERROR: " + createError.message + " </p>"
    tableCreated = false
  end

  if (tableCreated)
    rowID = 1
    dbError = false
    uploadedFile.drop(1).each do |row|
      rowValues = "'" + rowID.to_s() + "'"
      splitRow = row.split(",")

      columnIndex = 0
      splitRow.each do |value|
        if (value.strip() != "")
          rowValues = rowValues + ", '" + value.strip() + "'"
        else
          if (keys[0].to_s().strip() != "")
            keys.each do |key|
              if (columnNames[columnIndex].strip() == key.strip() and value.strip() == "")
                puts "<p> Error: The Primary Key " + columnNames[columnIndex].to_s() + " in Row " + rowID.to_s() + " does not have a value. Replacing with Not Entered " + rowID.to_s() + " </p>"
                rowValues = rowValues + ", 'Not Entered " + rowID.to_s() + "'"
              end
            end
          else
            puts "<p> Warning: Column " + columnNames[columnIndex].to_s() + " in Row " + rowID.to_s() + " does not have a value. Replacing with Not Entered </p>"
            rowValues = rowValues + ", 'Not Entered'"
          end
        end
      columnIndex = columnIndex + 1
      end

      begin
        massInsertDB.query("INSERT INTO " + massInsertCGI['tableName'].to_s() + " VALUES(" + rowValues + ");")
      rescue => insertError
        puts "<p> ERROR: " + insertError.message + " on row " + rowID.to_s() + " </p>"
        dbError = true
      end
      
      rowID = rowID + 1
    end
  end

  if (!dbError and tableCreated)
    puts "<h1> " + originalName.to_s() + " Uploaded Successfully! </h1>"
  else
    puts "<h1> " + originalName.to_s() + " had an error when uploading. </h1>"

    if (tableCreated)
      massInsertDB.query("DROP TABLE " + massInsertCGI['tableName'].to_s() + ";")
      puts "<h1> The table has been deleted. Please try again. </h1>"
    else
      puts "<h1> Please try again. </h1>"
    end
  end

  puts "</body>"
  puts "</html>" 
end
=end

# CSV column order: "bookId","title","series","author","rating","description","language","isbn","genres","characters","bookFormat","edition","pages","publisher","publishDate","firstPublishDate","awards","numRatings","ratingsByStars","likedPercent","setting","coverImg","bbeScore","bbeVotes","price"
# Authors currently in Books table, will need to move
booksFile.each do |book|
  splitBookRow = book.split("\",\"")
  title = splitBookRow[1].strip().gsub("'", "\\\\'")
  allAuthors = splitBookRow[3].strip()
  rating = splitBookRow[4].strip().to_f()
  #synopsis = splitBookRow[5].strip().gsub(["'"'"'], "'" => "\\\\'", '"' => '\\\\"')
  #(/[eo]/, 'e' => 3, 'o' => '*')
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

  if (title == "")
    puts "ERROR: Missing book title"
    title = "MISSING BOOK TITLE"
  end
  if (isbn == 0)
    puts "ERROR: Missing ISBN"
    isbn = -1
  end

=begin
  if (origSeqNumber == 0)
    puts "NOTICE: No Original Sequence Number given"
    origSeqNumber = -1
  end
  if (newSeqNumber == 0)
    puts "NOTICE: No New Sequence Number given"
    newSeqNumber = -1
  end
  if (status != "Completed" and status != "CASING" and status != "Sequence to do")
    if (status == "")
      puts "ERROR: Missing Status"
      status = "Missing"
    else
      puts "ERROR: Status must be Completed, CASING, or Sequence to do"
    end
  end
  if (date == "")
    puts "ERROR: Missing Date"
    date = "Missing"
  end
  if (month <= 0 or month > 12)
    puts "ERROR: Month must be an integer between 1 and 12"
    month = -1
  end
  if (year <= 0)
    puts "ERROR: Year must be an integer and cannot be 0"
    year = -1
  end
  if (researcher == "")
    puts "NOTICE: No researcher claimed"
    researcher = "Unclaimed"
  end
=end

  massInsertDB.query("INSERT INTO Books (title, author, lang_code, isbn, pg_nums, cover_img, rating) VALUES('" + title + "', '" + allAuthors + "', '" + lang_code + "', '" + isbn.to_s() + "', '" + pg_nums.to_s() + "', '" + cover_img + "', '" + rating.to_s() + "');")
end
