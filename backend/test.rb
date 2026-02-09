require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'

NYT_API_KEY = ENV.fetch('NYT_API_KEY')

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

# books = {}

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
puts titles
books = db.query("SELECT * FROM Books WHERE UPPER(title) IN #{titles};")


for b in books do
    puts "title: " + b['title']
end