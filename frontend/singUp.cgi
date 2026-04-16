#!/usr/bin/ruby
#File: singUp.cgi
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

usrName = cgi['usrName'].to_s.strip
email = cgi['email'].to_s.strip
password = cgi['password'].to_s
errorMessage = nil

if cgi.request_method == 'POST'
	if usrName.empty? || email.empty? || password.empty?
		errorMessage = 'Please fill out usrname, email, and password.'
	else
		created = createUser(usrName, password, email, db)
		if created
			puts "<!DOCTYPE html>"
			puts "<html>"
			puts "  <head>"
			puts "    <title>Redirecting...</title>"
			puts "  </head>"
			puts "  <body onload=\"document.getElementById('accountPostForm').submit();\">"
			puts "    <form id=\"accountPostForm\" method=\"post\" action=\"account.cgi\">"
			puts "      <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
			puts "    </form>"
			puts "    <noscript>"
			puts "      <button type=\"submit\" form=\"accountPostForm\">Continue to account</button>"
			puts "    </noscript>"
			puts "  </body>"
			puts "</html>"
			exit
		else
			errorMessage = 'Username or email already exists.'
			usrName = ''
		end
	end
end

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>Icarus - Sign Up</title>"
puts "        <link rel=\"icon\" type=\"image/x-icon\" href=\"../favicon.ico\" id=\"favicon\" />"
puts "        <link rel=\"stylesheet\" href=\"../Icarus.css\">"
puts "    </head>"
puts "    <body>"
if usrName == ""
puts "        <nav>"
puts "            <nav><a class=\"logo\" href=../index.cgi>Icarus</a></nav>"
puts "            <ul class=\"nav-links\">"
puts "                <li><a href=../index.cgi>Top Books</a></li>"
puts "                <li><a href=\"../frontend/search.cgi\">Search</a></li>"
puts "                <li><a href=\"../frontend/readingLog.cgi\">Reading Log</a></li>"
puts "                <li><a href=\"../frontend/signIn.cgi\">Sign In</a></li>"
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
puts "                <li><form class=\"nav-post-form\" action=\"../frontend/readingLog.cgi\" method=\"POST\">"
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

puts "        <div class=\"signin-wrapper\">"
puts "        <h1>Create Account</h1>"
puts "        <form class=\"signin-form\" method=\"post\" action=\"singUp.cgi\">"
puts "            <label for=\"usrName\">Username:</label>"
puts "            <input type=\"text\" id=\"usrName\" name=\"usrName\" maxlength=\"100\" value=\"#{CGI.escapeHTML(usrName)}\" required>"
puts "            <label for=\"email\">Email:</label>"
puts "            <input type=\"text\" inputmode=\"email\" id=\"email\" name=\"email\" maxlength=\"255\" value=\"#{CGI.escapeHTML(email)}\" pattern=\"[a-z0-9._%+\\-]+@[a-z0-9.\\-]+\\.[a-z]{2,4}\" title=\"Please enter a valid email address (e.g. user@example.com)\" required>"
puts "            <label for=\"password\">Password:</label>"
puts "            <input type=\"password\" id=\"password\" name=\"password\" maxlength=\"255\" required>"
puts "            <input type=\"submit\" class=\"signin-submit\" value=\"Create Account\">"
puts "        </form>"

if errorMessage
	puts "        <p>#{CGI.escapeHTML(errorMessage)}</p>"
end

puts "        </div>"

puts "    </body>"
puts "</html>"