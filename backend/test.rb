#!/usr/bin/ruby

# File to test ruby code

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

=begin
require_relative '../env_loader'

NYT_API_KEY = ENV.fetch('NYT_API_KEY')

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

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

uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=J. R. R. Tolkien&prop=wikitext&section=0&format=json")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)
authorInfo = data.dig("parse", "wikitext", "*")
#puts authorInfo
#puts authorInfo.class()

authorBio = ""
bioStart = false
authorInfo.split(" ").each do |word|  
  if word == "'''John"
    bioStart = true
  end
  if bioStart == true
    authorBio = authorBio + word + " "
  end
end
puts authorBio
authorBio = authorBio.gsub!(/\{\{.*?\}\}/, "")
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
cleanBio = cleanBio.gsub("'", "")
cleanBio = cleanBio.gsub("]", "")
cleanBio = cleanBio.gsub("{", "")
cleanBio = cleanBio.gsub("}", "")
cleanBio = cleanBio.gsub("/ref>", "")
puts cleanBio

#puts authorBio