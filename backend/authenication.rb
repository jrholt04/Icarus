require 'bcrypt'
require 'mysql2'
require 'stringio'

require_relative '../env_loader'

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

def createUser(username, password, email, db)
    passwordHash = createPasswordHash(password)
    if userExists(db, username)
        return false
    end
    if emailExists(db, email)
        return false
    end
    db.query("INSERT INTO Users (username, pswd, email) VALUES ('#{db.escape(username)}', '#{db.escape(passwordHash)}', '#{db.escape(email)}');")
    return true 
end

def verifyPassword(password, usr_name, db)
    hassedPassword = BCrypt::Password.new(password)
    usr_id_row = db.query("SELECT usr_id FROM Users WHERE usr_name = '#{db.escape(usr_name)}';").first
    storedPass = db.query("SELECT pswd FROM Users WHERE id = #{db.escape(usr_id.to_s)};").first
    if storedPass == hassedPassword
        return true
    else
        return false
    end
end

def signIn(username, password, db)
    if verifyPassword(password, username, db)
        return true
    else
        return false
    end
end

def createPasswordHash(password)
  newPass = BCrypt::Password.create(password)
  return newPass.to_s
end

def userExists(db, username)
    result = db.query("SELECT COUNT(*) AS count FROM Users WHERE username = '#{db.escape(username)}';").first
    return result && result['count'] > 0
end

def emailExists(db, email)
    result = db.query("SELECT COUNT(*) AS count FROM Users WHERE email = '#{db.escape(email)}';").first
    return result && result['count'] > 0
end