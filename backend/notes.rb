#!/usr/bin/ruby

# FILE: notes.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
# Backend script for notes-related database operations.

$stdout.sync = true
$stderr.reopen $stdout

require 'cgi'
require 'mysql2'
require 'stringio'

require_relative '../env_loader'

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

def createNote(user_id, book_id, content, db)
    db.query("INSERT INTO Notes (usr_id, book_id, note) VALUES (#{user_id.to_i}, #{book_id.to_i}, '#{db.escape(content)}');")
end

def deleteNote(note_id, db)
    db.query("DELETE FROM Notes WHERE note_id = #{note_id.to_i}")
end

def findUserId(usrName, db)
    user = db.query("SELECT usr_id FROM Users WHERE usr_name = '#{db.escape(usrName.to_s)}';").first
    return nil if user.nil?

    return user['usr_id']
end