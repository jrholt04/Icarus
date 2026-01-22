#!/usr/bin/ruby

# FILE: uploadAndPopulate.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to create and populate a table from a CSV file submitted through index.html
# User submits the file, table name, and key(s) they want to use, and leaving the key blank indicates they want the key to be a unique id
# If any of the key(s) entered are not present in the header of the CSV, the user is taken to a new form where they can choose from a
# list of possible keys. Again, selecting nothing indicates they want the key to be a unique id
# If the table name entered already exists in the database, the user is prompted to select a new table name
# If the table name is invalid, the user is prompted to enter a valid table name
# If there are duplicate keys, the user is informed where the error was and the table is deleted
# This program does not check to ensure the file submitted is a .csv file, nor does it check whether the CSV file is empty
# Sources:
#   Hidden Input Type - https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/hidden - Accessed 5 March 2025
#   Gsub in Ruby - https://ruby-doc.org/core-2.4.5/String.html#method-i-gsub - Accessed 5 March 2025
#   Making Required Fields in Table - https://www.geeksforgeeks.org/how-to-perform-form-validation-for-a-required-field-in-html/ - Accessed 5 March 2025
#   Show Tables - https://dev.mysql.com/doc/refman/8.4/en/show-tables.html - Accessed 7 March 2025


$stdout.sync = true
$stderr.reopen $stdout

puts "Content-type: text/html\r\n\r\n" 

require 'cgi'
require 'mysql2'
require 'stringio'

massInsertDB = Mysql2::Client.new(:host => '10.20.3.4', :username => 'Icarus', :password => 'B00kz!', :database => 'ss_icarus_db')
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
validTableName = true
allTables = massInsertDB.query("SHOW TABLES;")
allTables.each do |table|
  if (table['Tables_in_dbms_ek_dbA'] == massInsertCGI['tableName'].to_s())
    validTableName = false
  end
end

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
