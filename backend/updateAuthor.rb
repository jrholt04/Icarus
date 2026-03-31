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

def noBio(db, a)
    authorBooksList = ""
    authorBooks = db.query("SELECT b.* FROM BookAuth ba JOIN Books b ON b.book_id = ba.book_id WHERE ba.auth_id = '" + a["auth_id"].to_s() + "' ORDER BY b.publish_date DESC;")
    authorBooks.each do |book|
        authorBooksList = authorBooksList + "<i>" + book["title"].gsub(/\w+/) { |word| word.capitalize } + "</i>, "
    end
    authorBooksList = authorBooksList.strip()
    authorBooksList = authorBooksList.gsub("'", "\\\\'")
    authorBooksList[authorBooksList.length() - 1] = "."
    db.query("UPDATE Authors SET bio = '" + a["name"] + " authored or contributed to " + authorBooksList + "' WHERE auth_id = '" + a["auth_id"].to_s() + "';")
end

allAuthors = icarusDB.query("SELECT * FROM Authors")

allAuthors.each do |author|
    puts author["bio"]
    authorName = author["name"].gsub(".", "._")
    authorName = authorName.gsub(" ", "_")
    authorName = authorName.gsub("__", "_")
    authorName = URI.encode_www_form_component(authorName)
    uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{authorName}&prop=wikitext&section=0&format=json")
    res = Net::HTTP.get_response(uri)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)
    authorInfo = data.dig("parse", "wikitext", "*")

    # If there is no Wikipedia page, default to the generic author bio and move to the next author
    if authorInfo.nil?
        noBio(icarusDB, author)
        next
    end

    # Check if the page is ambiguous and redirect if necessary
    ambiguousText = /may refer to/
    ambiguousAuthor = authorInfo.split("[[")
    if ambiguousText.match(ambiguousAuthor[0])
        sleep(2)
        uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{authorName}_(author)&prop=wikitext&section=0&format=json")
        res = Net::HTTP.get_response(uri)
        raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        authorInfo = data.dig("parse", "wikitext", "*")
    end

    # Check if the author is being redirected
    redirectText = /#REDIRECT/
    numBrackets = 0
    correctedAuthorName = ""
    if redirectText.match(authorInfo)
        # If there is a redirect, find the correct author name (contained within the first double set of square brackets)
        authorInfo.split("").each do |char|
            if char == "[" or char == "]"
                numBrackets = numBrackets + 1
            end
            if numBrackets == 2 and char != "["
                correctedAuthorName = correctedAuthorName + char
            end
            if numBrackets > 2
                break
            end
        end
        # Redirect to the correct Wikipedia page
        sleep(2)
        correctedAuthorName = URI.encode_www_form_component(correctedAuthorName)
        uri = URI("https://en.wikipedia.org/w/api.php?action=parse&page=#{correctedAuthorName}&prop=wikitext&section=0&format=json")
        res = Net::HTTP.get_response(uri)
        raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        authorInfo = data.dig("parse", "wikitext", "*")
    end

    # If either redirect does not find a Wikipedia page, set default bio
    if authorInfo.nil?
        noBio(icarusDB, author)
        next
    end

    # Cut out any miscelaneous WikiText at the beginning of the bio
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

    if authorBio.nil?
        noBio(icarusDB, author)
        next
    end

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

    # If there are book titles in the bio, adds a italics tags to either side of them
    italicsBio = ""
    cleanBio.split(" ").each do |word|  
        if word[0,2] == "''" and word[0,3] != "'''" and /''/.match(word[2,word.length()])
            italicsBio = italicsBio + "<i>" + word + "</i> "
        elsif word[0,2] == "''" and word[0,3] != "'''"
            italicsBio = italicsBio + "<i>" + word + " "
        elsif /''/.match(word) and !/'''/.match(word)
            italicsBio = italicsBio + word + "</i> "
        else
            italicsBio = italicsBio + word + " "
        end
    end
    cleanBio = italicsBio

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

    # If, after cleaning, the bio is empty, set default bio
    if cleanBio.strip() == ""
        noBio(icarusDB, author)
        next
    end

    icarusDB.query("UPDATE Authors SET bio = '" + cleanBio[0,10000] + "' WHERE auth_id = '" + author["auth_id"].to_s() + "';")
    sleep(2)
    puts "Updated bio for " + author["name"]
end
