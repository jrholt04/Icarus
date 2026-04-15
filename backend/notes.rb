#!/usr/bin/ruby

# FILE: notes.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Backend script for notes-related database operations.

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'date'
require 'mysql2'
require 'stringio'

require_relative '../env_loader'

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

def createNote(userId, bookId, content, db)
    datedContent = "Note #{Date.today}:<br>#{content.to_s.strip}"
    db.query("INSERT INTO Notes (usr_id, book_id, note) VALUES (#{userId.to_i}, #{bookId.to_i}, '#{db.escape(datedContent)}');")
end

def deleteNote(noteId, db)
    db.query("DELETE FROM Notes WHERE note_id = #{noteId.to_i}")
end

def findUserId(usrName, db)
    user = db.query("SELECT usr_id FROM Users WHERE usr_name = '#{db.escape(usrName.to_s)}';").first
    return nil if user.nil?

    return user['usr_id']
end