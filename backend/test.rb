require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'
db = Mysql2::Client.new(
    :host=>'10.20.3.4',
    :username=>'Icarus',
    :password=>'B00kz!',
    :database=>'ss_icarus_db'
    )

# books = {}

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
puts titles
books = db.query("SELECT * FROM Books WHERE UPPER(title) IN #{titles};")


for b in book do
    puts "title: " + b['title']
end