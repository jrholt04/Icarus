#!/usr/bin/ruby

# File to test ruby code

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'


require_relative '../env_loader'

NYT_API_KEY = ENV.fetch('NYT_API_KEY')

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

=begin
# books = {}

uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-nonfiction.json?api-key=#{NYT_API_KEY}")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
author = data.dig("knowledge_graph", "description")

puts author

# Google API to get the ISBN of the book.
def getBookPublishDate(title)
  uri = URI("https://www.googleapis.com/books/v1/volumes?q=#{title}")
  res = Net::HTTP.get_response(uri)
  data = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
  publishDate = data.dig('items', 0, 'volumeInfo', 'publishedDate') if data
  return publishDate
end

getBookPublishDate("Hunger Games")
=end
=begin

name = "Virginia Roberts Giuffre"

uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{name}&prop=wikitext&section=0&format=json")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
authorInfo = data.dig("parse", "wikitext", "*")
puts authorInfo
#puts authorInfo.class()

if authorInfo.nil?
  authorBooksList = ""
  authorBooks = db.query("SELECT b.* FROM BookAuth ba JOIN Books b ON b.book_id = ba.book_id WHERE ba.auth_id = '579' ORDER BY b.publish_date DESC;")
  authorBooks.each do |book|
    authorBooksList = authorBooksList + book["title"].gsub(/\w+/) { |word| word.capitalize } + ", "
  end
  authorBooksList = authorBooksList.strip()
  authorBooksList[authorBooksList.length() - 1] = "."
  puts authorBooksList
  return
  #icarusDB.query("UPDATE Authors SET bio = '" + author["name"] + " is the author of " + authorBooksList + ".' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
end

# Check if the page is ambiguous
ambiguousText = /may refer to/
ambiguousAuthor = authorInfo.split("[[")
if ambiguousText.match(ambiguousAuthor[0])
  sleep(2)
  uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{name}_(author)&prop=wikitext&section=0&format=json")
  res = Net::HTTP.get_response(uri)
  raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
  data = JSON.parse(res.body)
  authorInfo = data.dig("parse", "wikitext", "*")
end

# Check if the author is being redirected
redirectText = /#REDIRECT/
numBrackets = 0
correctedAuthorName = ""
if redirectText.match(authorInfo)
  # If there is a redirect, find the correct author name 
  authorInfo.split("").each do |char|
    if char == "[" or char == "]"
      numBrackets = numBrackets + 1
    end
    if numBrackets == 2 and char != "["
      correctedAuthorName = correctedAuthorName + char
    end
    if numBrackets > 2
      break
    end
  end
  # Redirect to the correct Wikipedia page
  sleep(2)
  uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{correctedAuthorName}&prop=wikitext&section=0&format=json")
  res = Net::HTTP.get_response(uri)
  raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
  data = JSON.parse(res.body)
  authorInfo = data.dig("parse", "wikitext", "*")
end
puts correctedAuthorName

authorBio = ""
bioStart = false
authorInfo.split(" ").each do |word|  
  if word[0,3] == "'''"
    bioStart = true
  end
  if bioStart == true
    authorBio = authorBio + word + " "
  end
end
puts authorBio
authorBio = authorBio.gsub(/\{\{.*?\}\}/, "")
puts
puts
#authorBio = authorBio.gsub("'", "")
#authorBio = authorBio.gsub("[", "")
#authorBio = authorBio.gsub("]", "")
#authorBio = authorBio.gsub("|", "/")
#authorBio = authorBio.gsub!(/\[\[.*?\|/, "")
#authorBio = authorBio.gsub(/^(?=^\[\[)(?=.*\|$)(?=^(?:(?!\]\]).)*$).*$/, "")
#authorBio = authorBio.gsub!(/(\[\[.*?\|)(~?.*?\]\].*?)/, "")

# Remove links
unlinkedBio = ""
#linkText = /ref/
splitLinkBio = authorBio.split("<")
splitLinkBio.each do |possibleLink|
  #if !linkText.match(possibleLink)
  if possibleLink[0,3] != "ref"
    unlinkedBio = unlinkedBio + possibleLink
  end
end
puts unlinkedBio
puts
puts

firstLine = true
cleanBio = ""
wikiText = /\|/
splitBio = unlinkedBio.split("[[") 
splitBio.each do |bioPiece|
  if firstLine
    cleanBio = cleanBio + bioPiece
    firstLine = false
    next
  end

  if wikiText.match(bioPiece)
    cleanBio = cleanBio + bioPiece.gsub!(/.*?\|/, "")
  else
    cleanBio = cleanBio + bioPiece
  end
end

italicsBio = ""
cleanBio.split(" ").each do |word|  
  if word[0,2] == "''" and word[0,3] != "'''" and /''/.match(word[2,word.length()])
    italicsBio = italicsBio + "<i>" + word + "</i> "
  elsif word[0,2] == "''" and word[0,3] != "'''"
    italicsBio = italicsBio + "<i>" + word + " "
  elsif /''/.match(word) and !/'''/.match(word)
    italicsBio = italicsBio + word + "</i> "
  else
    italicsBio = italicsBio + word + " "
  end
end
puts italicsBio
puts
puts
cleanBio = italicsBio

cleanBio = cleanBio.gsub(/\!--.*?--\>/, "")
cleanBio = cleanBio.gsub("&nbsp;", " ")
cleanBio = cleanBio.gsub("/ref>", "")
cleanBio = cleanBio.gsub("/ref>", "")
cleanBio = cleanBio.gsub("/ref>", "")
cleanBio = cleanBio.gsub("nowiki/>", "")
cleanBio = cleanBio.gsub("'", "")
cleanBio = cleanBio.gsub("]", "")
cleanBio = cleanBio.gsub("{", "")
cleanBio = cleanBio.gsub("}", "")
cleanBio = cleanBio.gsub("( ; ", "(")
cleanBio = cleanBio.gsub("(; ", "(")
cleanBio = cleanBio.gsub("(; ", "(")
puts cleanBio
puts cleanBio.class()

if cleanBio.nil? or cleanBio.strip() == ""
  authorBooksList = ""
  authorBooks = db.query("SELECT b.* FROM BookAuth ba JOIN Books b ON b.book_id = ba.book_id WHERE ba.auth_id = '500' ORDER BY b.publish_date DESC;")
  authorBooks.each do |book|
    authorBooksList = authorBooksList + book["title"].gsub(/\w+/) { |word| word.capitalize } + ", "
  end
  authorBooksList = authorBooksList.strip()
  authorBooksList[authorBooksList.length() - 1] = "."
  puts authorBooksList
  return
  #icarusDB.query("UPDATE Authors SET bio = '" + author["name"] + " is the author of " + authorBooksList + ".' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
end

#puts authorBio

#Barbara A. Mowat
#C.M. Woodhouse

puts URI.encode_www_form_component("Emily_Brontë")
=end
# First author of NYT id = 507
# First book of NYT id = 447
=begin
authorBio = db.query("SELECT * FROM Authors WHERE auth_id = 580;").first()
puts authorBio["bio"] != ""
=end

puts db.query("SELECT * FROM Books WHERE title = 'dfghjk';").first().nil?()