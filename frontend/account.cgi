#!/usr/bin/ruby
#File: account.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus
        
#   This is the sign-in/user profile page for Icarus

$stdout.sync = true 
$stderr.reopen $stdout 

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'
require 'net/http'
require 'json'

require_relative '../env_loader'

db = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

#get info from html forms
cgi = CGI.new("html5")

usrName = cgi['usrName']

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Icarus</title>"
puts "        <link rel=\"icon\" type=\"image/x-icon\" href=\"../favicon.ico\" id=\"favicon\" />"
puts "        <link rel=\"stylesheet\" href=\"../Icarus.css\">"
puts "        <script>"
puts "            function updateFavicon() {"
puts "                const favicon = document.getElementById('favicon');"
puts "                const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;"
puts "                favicon.href = isDark ? '../faviconwhite.ico' : '../favicon.ico';"
puts "            }"
puts "            updateFavicon();"
puts "            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateFavicon);"
puts "        </script>"
puts "    </head>"
puts "    <body>"
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=../index.cgi?usrName=#{CGI.escape(usrName)}>Top Books</a></li>"
puts "                <li><a href=\"../frontend/search.cgi\">Search</a></li>"
puts "                <li><a href=\"#reading-log\">Reading Log</a></li>"
                        if usrName == ""
puts "                      <li><a href=\"account.cgi\">Sign In</a></li>"
                        else 
puts "                      <li><a href=\"account.cgi\">#{usrName}</a></li>"
                        end
puts "            </ul>"
puts "        </nav>"
if usrName == ""
    puts "        <h1>you're not signed in!</h1>"
    puts "        <a class=\"sign-in-links\" href=\"signIn.cgi\">Sign in</a>"
    puts "        <br>"
    puts "        <a class=\"sign-in-links\" href=\"singUp.cgi\">Create an account</a>"
else
    user = db.query("SELECT * FROM Users WHERE usr_name = '#{db.escape(usrName)}';").first  
    puts "        <h1>Welcome, #{user['usr_name']}!</h1>"
    puts "        <h1>Email: #{user['email']}</h1>"
    puts "        <a href=\"account.cgi\">Sign out</a>"
end
puts "    </body>"
puts "</html>"