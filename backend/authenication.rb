#File: authenication.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
#
#   This is the functions that will be used for user authentication, including creating users, signing in, and password hashing. It uses the bcrypt gem for secure password hashing and the mysql2 gem to interact with the
#   MySQL database. The functions include:
#
#
require 'bcrypt'
require 'mysql2'
require 'stringio'

require_relative '../env_loader'

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

# Function to create a new user with a hashed password. It checks if the username or email already exists before inserting the new user into the database.
def createUser(username, password, email, db)
    passwordHash = createPasswordHash(password)
    if userExists(db, username)
        return false
    end
    if emailExists(db, email)
        return false
    end
    db.query("INSERT INTO Users (usr_name, pswd, email) VALUES ('#{db.escape(username)}', '#{db.escape(passwordHash)}', '#{db.escape(email)}');")
    return true 
end

# Function to verify a user's password by comparing the provided password with the stored hashed password in the database.
def verifyPassword(password, usr_name, db)
    if !userExists(db, usr_name) || usr_name.nil? || usr_name.strip.empty?
        return false
    end
    user_row = db.query("SELECT pswd FROM Users WHERE usr_name = '#{db.escape(usr_name)}';").first
    stored_password_hash = BCrypt::Password.new(user_row['pswd'])
    return stored_password_hash == password
end

# Function to sign in a user by verifying their password. It returns true if the password is correct, and false otherwise.
def signIn(username, password, db)
    if verifyPassword(password, username, db)
        return true
    else
        return false
    end
end

# Function to create a hashed password using bcrypt. It takes a plain text password and returns the hashed version.
def createPasswordHash(password)
  newPass = BCrypt::Password.create(password)
  return newPass.to_s
end

# Function to check if a user with the given username already exists in the database. It returns true if the user exists, and false otherwise.
def userExists(db, username)
    result = db.query("SELECT COUNT(*) AS count FROM Users WHERE usr_name = '#{db.escape(username)}';").first
    return result && result['count'] > 0
end

# Function to check if an email already exists in the database. It returns true if the email exists, and false otherwise.
def emailExists(db, email)
    result = db.query("SELECT COUNT(*) AS count FROM Users WHERE email = '#{db.escape(email)}';").first
    return result && result['count'] > 0
end