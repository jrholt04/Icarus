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

usrName = cgi['usrName'].to_s.strip

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
if usrName == ""
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=../index.cgi>Top Books</a></li>"
puts "                <li><a href=\"../frontend/search.cgi\">Search</a></li>"
puts "                <li><a href=\"../frontend/readingLog.cgi\">Reading Log</a></li>"
puts "                <li><a href=\"account.cgi\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
else
puts "        <nav>"
puts "            <nav><form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\"><input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\"><button type=\"submit\" class=\"nav-logo-button\">Icarus</button></form></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Top Books</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"../frontend/search.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Search</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"../frontend/readingLog.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Reading Log</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"account.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">#{CGI.escapeHTML(usrName)}</button>"
puts "                    </form>"
puts "                </li>"
puts "            </ul>"
puts "        </nav>"
end
if usrName == ""
    puts "        <h1>Profile</h1>"
    puts "        <hr class=\"profile-divider\">"
    puts "        <a class=\"sign-in-links\" href=\"signIn.cgi\">Sign in</a>"
    puts "        <br>"
    puts "        <a class=\"sign-in-links\" href=\"singUp.cgi\">Create an account</a>"
else
    user = db.query("SELECT * FROM Users WHERE usr_name = '#{db.escape(usrName)}';").first  
    puts "        <h1>Profile</h1>"
    puts "        <hr class=\"profile-divider\">"
    puts "        <h1>Username: #{CGI.escapeHTML(usrName)}</h1>"
    puts "        <h1>Email: #{user['email']}</h1>"
    puts "        <a class=\"sign-in-links\" href=\"account.cgi\">Sign out</a>"
end
puts "    </body>"
puts "</html>"