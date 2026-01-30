require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

books = []
db = Mysql2::Client.new(:host => '10.20.3.4', :username => 'Icarus', :password => 'B00kz!', :database => 'ss_icarus_db')
print "starting api test\n"
uri = URI("https://api.nytimes.com/svc/books/v3/lists/current/combined-print-and-e-book-fiction.json?api-key=klviqNxHeAn1sJLagvrTmACJIaYZ6aPRLv6hMCABttZcAcuF")
res = Net::HTTP.get_response(uri)
raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
data = JSON.parse(res.body)

ficBooks = data.dig("results", "books")
puts "books count: #{ficBooks.size}"
ficBooks.each do |b|
    puts "Title: #{b['title']}"
    books.push(db.query("SELECT * FROM books WHERE title = '#{b['title']}';"))
    puts "Book found in database."
end
return books

# return books.first(10)
