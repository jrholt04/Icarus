#!/usr/bin/ruby

# FILE: updateAuthor.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Ruby program to update the authors in the Authors table with their biographical information as found on Wikipedia

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'
require 'net/http'
require 'json'

require_relative '../env_loader'

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

allAuthors = icarusDB.query("SELECT * FROM Authors")

allAuthors.each do |author|
    authorName = author["name"].tr("ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëễĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž", "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
    authorName = authorName.gsub(".", "._")
    authorName = authorName.gsub(" ", "_")
    authorName = authorName.gsub("__", "_")
    uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{authorName}&prop=wikitext&section=0&format=json")
    res = Net::HTTP.get_response(uri)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)
    authorInfo = data.dig("parse", "wikitext", "*")

    puts
    puts authorInfo
    puts

    if authorInfo.nil?
        authorBooksList = ""
        authorBooks = icarusDB.query("SELECT b.* FROM BookAuth ba JOIN Books b ON b.book_id = ba.book_id WHERE ba.auth_id = '" + author["auth_id"].to_s() + "' ORDER BY b.publish_date DESC;")
        authorBooks.each do |book|
            authorBooksList = authorBooksList + book["title"] + ", "
        end
        authorBooksList = authorBooksList.strip()
        authorBooksList[authorBooksList.length() - 1] = "."
        authorBooksList = authorBooksList.gsub("'", "\\\\'")
        icarusDB.query("UPDATE Authors SET bio = '" + author["name"] + " is the author of " + authorBooksList + ".' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
        next
    end

    # Check if the page is ambiguous
    ambiguousText = /may refer to/
    ambiguousAuthor = authorInfo.split("[[")
    if ambiguousText.match(ambiguousAuthor[0])
        sleep(1)
        uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{authorName}_(author)&prop=wikitext&section=0&format=json")
        res = Net::HTTP.get_response(uri)
        raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        authorInfo = data.dig("parse", "wikitext", "*")
    end

    #if authorInfo.nil?
    #    icarusDB.query("UPDATE Authors SET bio = 'No Biography Found' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
    #    next
    #end
    if authorInfo.nil?
        authorBooksList = ""
        authorBooks = icarusDB.query("SELECT b.* FROM BookAuth ba JOIN Books b ON b.book_id = ba.book_id WHERE ba.auth_id = '" + author["auth_id"].to_s() + "' ORDER BY b.publish_date DESC;")
        authorBooks.each do |book|
            authorBooksList = authorBooksList + book["title"] + ", "
        end
        authorBooksList = authorBooksList.strip()
        authorBooksList[authorBooksList.length() - 1] = "."
        icarusDB.query("UPDATE Authors SET bio = '" + author["name"] + " is the author of " + authorBooksList + ".' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
        next
    end

    #puts 
    #puts authorInfo
    #puts

    authorFirstName = author["name"].split(" ").first()
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

    # Removes any instances of {{ }}
    authorBio = authorBio.gsub(/\{\{.*?\}\}/, "")

    #if authorBio.nil?
    #    icarusDB.query("UPDATE Authors SET bio = 'No Biography Found' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
    #    next
    #end

    # Remove links
    unlinkedBio = ""
    splitLinkBio = authorBio.split("<")
    splitLinkBio.each do |possibleLink|
        if possibleLink[0,3] != "ref"
            unlinkedBio = unlinkedBio + possibleLink
        end
    end

    # Removes the first half of any Wikipedia link in [[ ]] where there is alternate text
    # Displays only the written text while removing the link
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

    # Removes any extraneous symbols leftover after cleaning
    cleanBio = cleanBio.gsub(/\!--.*?--\>/, "")
    cleanBio = cleanBio.gsub("&nbsp;", " ")
    cleanBio = cleanBio.gsub("/ref>", "")
    cleanBio = cleanBio.gsub("nowiki/>", "")
    cleanBio = cleanBio.gsub("'", "")
    cleanBio = cleanBio.gsub("]", "")
    cleanBio = cleanBio.gsub("{", "")
    cleanBio = cleanBio.gsub("}", "")
    cleanBio = cleanBio.gsub("( ; ", "(")
    cleanBio = cleanBio.gsub("(; ", "(")
    cleanBio = cleanBio.gsub("(; ", "(")

    icarusDB.query("UPDATE Authors SET bio = '" + cleanBio[0,1000] + "' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
    sleep(1)
end
