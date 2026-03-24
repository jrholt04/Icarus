#!/usr/bin/ruby
#File: singIn.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus

$stdout.sync = true
$stderr.reopen $stdout

print "Content-type: text/html\n\n"

require 'mysql2'
require 'cgi'
require_relative '../env_loader'
require_relative '../backend/authenication'

cgi = CGI.new("html5")
db = Mysql2::Client.new(
	:host => ENV.fetch('ICARUS_DB_HOST'),
	:username => ENV.fetch('ICARUS_DB_USER'),
	:password => ENV.fetch('ICARUS_DB_PASSWORD'),
	:database => ENV.fetch('ICARUS_DB_NAME')
)

usr_name = cgi['usrName'].to_s.strip
password = cgi['password'].to_s
error_message = nil

if cgi.request_method == 'POST'
	if usr_name.empty? || password.empty?
		error_message = 'Please fill out username and password.'
	elsif signIn(usr_name, password, db)
		puts "<!DOCTYPE html>"
		puts "<html>"
		puts "  <head>"
		puts "    <title>Redirecting...</title>"
		puts "  </head>"
		puts "  <body onload=\"document.getElementById('accountPostForm').submit();\">"
		puts "    <form id=\"accountPostForm\" method=\"post\" action=\"account.cgi\">"
		puts "      <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usr_name)}\">"
		puts "    </form>"
		puts "    <noscript>"
		puts "      <button type=\"submit\" form=\"accountPostForm\">Continue to account</button>"
		puts "    </noscript>"
		puts "  </body>"
		puts "</html>"
		exit
	else
		error_message = 'Incorrect username or password.'
	end
end

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Icarus - Sign In</title>"
puts "        <link rel=\"icon\" type=\"image/x-icon\" href=\"../favicon.ico\" id=\"favicon\" />"
puts "        <link rel=\"stylesheet\" href=\"../Icarus.css\">"
puts "    </head>"
puts "    <body>"
if usr_name == ""
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=../index.cgi>Top Books</a></li>"
puts "                <li><a href=\"../frontend/search.cgi\">Search</a></li>"
puts "                <li><a href=\"#reading-log\">Reading Log</a></li>"
puts "                <li><a href=\"account.cgi\">Sign In</a></li>"
puts "            </ul>"
puts "        </nav>"
else
puts "        <nav>"
puts "            <nav><form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\"><input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usr_name)}\"><button type=\"submit\" class=\"nav-logo-button\">Icarus</button></form></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"../index.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usr_name)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Top Books</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"../frontend/search.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usr_name)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">Search</button>"
puts "                    </form>"
puts "                </li>"
puts "                <li><a href=\"#reading-log\">Reading Log</a></li>"
puts "                <li>"
puts "                    <form class=\"nav-post-form\" action=\"account.cgi\" method=\"POST\">"
puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usr_name)}\">"
puts "                        <button type=\"submit\" class=\"nav-post-button\">#{CGI.escapeHTML(usr_name)}</button>"
puts "                    </form>"
puts "                </li>"
puts "            </ul>"
puts "        </nav>"
end

puts "        <h1>Sign In</h1>"
puts "        <form method=\"post\" action=\"signIn.cgi\">"
puts "            <label for=\"usrName\">Username:</label><br>"
puts "            <input type=\"text\" id=\"usrName\" name=\"usrName\" value=\"#{CGI.escapeHTML(usr_name)}\" required><br>"
puts "            <label for=\"password\">Password:</label><br>"
puts "            <input type=\"password\" id=\"password\" name=\"password\" required><br><br>"
puts "            <input type=\"submit\" value=\"Sign In\">"
puts "        </form>"
puts "        <p>Need an account? <a href=\"singUp.cgi\">Create one</a></p>"

if error_message
	puts "        <p>#{CGI.escapeHTML(error_message)}</p>"
end

puts "    </body>"
puts "</html>"

