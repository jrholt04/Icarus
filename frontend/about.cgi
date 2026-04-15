#!/usr/bin/ruby
#File: about.cgi
#Azalea Flynn, Erin Kendall, Jackson Holt, Transy U
#Dr. Moorman, Icarus

#   This is the about page for Icarus

$stdout.sync = true
$stderr.reopen $stdout

print "Content-type: text/html\n\n"

require 'cgi'

cgi = CGI.new("html5")
usrName = cgi['usrName'].to_s.strip

# Use the published Google Doc preview URL format:
# https://docs.google.com/document/d/<DOC_ID>/preview
ourPaperDocUrl = "https://docs.google.com/document/d/1aNxy3xsNyGdMSp5sdDC2JnRSPKpAC11t4ImpzOUZrow/preview"

def renderGoogleDocEmbed(docUrl, fallbackText)
    escapedUrl = CGI.escapeHTML(docUrl)
    puts "                    <iframe class=\"about-doc-frame\" src=\"#{escapedUrl}\" title=\"#{fallbackText}\"></iframe>"
end

puts "<!DOCTYPE html>"
puts "<html>"
puts "    <head>"
puts "        <title>About</title>"
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
    puts "                <li><a href=\"search.cgi\">Search</a></li>"
    puts "                <li><a href=\"readingLog.cgi\">Reading Log</a></li>"
    puts "                <li><a href=\"signIn.cgi\">Sign In</a></li>"
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
    puts "                    <form class=\"nav-post-form\" action=\"search.cgi\" method=\"POST\">"
    puts "                        <input type=\"hidden\" name=\"usrName\" value=\"#{CGI.escapeHTML(usrName)}\">"
    puts "                        <button type=\"submit\" class=\"nav-post-button\">Search</button>"
    puts "                    </form>"
    puts "                </li>"
    puts "                <li>"
    puts "                    <form class=\"nav-post-form\" action=\"readingLog.cgi\" method=\"POST\">"
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

puts "        <div class=\"about-layout\">"
puts "            <aside class=\"about-sidebar\">"
puts "                <table class=\"about-menu-table\">"
puts "                    <tr><td><a href=\"#our-paper\">Our Paper</a></td></tr>"
puts "                    <tr><td><a href=\"#ci-cd\">CI/CD Pipeline and Setup</a></td></tr>"
puts "                </table>"
puts "            </aside>"

puts "            <main class=\"about-main\">"
puts "                <section id=\"our-paper\" class=\"about-section\">"
puts "                    <h1>Our Paper</h1>"
puts "                    <iframe class=\"about-doc-frame\" src=\"https://docs.google.com/document/d/1aNxy3xsNyGdMSp5sdDC2JnRSPKpAC11t4ImpzOUZrow/preview\" title=\"cannot find paper\"></iframe>"
puts "                </section>"

puts "                <section id=\"ci-cd\" class=\"about-section\">"
puts "                    <h1>CI/CD Pipeline and Setup</h1>"
puts "                    <p class=\"about-copy\">This section will document the CI/CD setup for Icarus, including test automation, deployment flow, and environment configuration.</p>"
puts "                </section>"
puts "            </main>"
puts "        </div>"

puts "    </body>"
puts "</html>"