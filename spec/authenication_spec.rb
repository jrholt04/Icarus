require 'spec_helper'
require_relative '../backend/authenication'

RSpec.describe 'Authentication functions' do
  let(:db) { instance_double('Mysql2::Client') }

  describe '#createUser' do
    it 'returns true and inserts user when username and email are available' do
      allow(self).to receive(:createPasswordHash).with('secret').and_return('hashed_secret')
      allow(self).to receive(:userExists).with(db, 'alice').and_return(false)
      allow(self).to receive(:emailExists).with(db, 'alice@example.com').and_return(false)
      allow(db).to receive(:escape) { |value| "escaped_#{value}" }

      expect(db).to receive(:query).with("INSERT INTO Users (usr_name, pswd, email) VALUES ('escaped_alice', 'escaped_hashed_secret', 'escaped_alice@example.com');")

      expect(createUser('alice', 'secret', 'alice@example.com', db)).to be(true)
    end

    it 'returns false when username already exists' do
      allow(self).to receive(:createPasswordHash).and_return('hashed_secret')
      allow(self).to receive(:userExists).with(db, 'alice').and_return(true)

      expect(db).not_to receive(:query)
      expect(createUser('alice', 'secret', 'alice@example.com', db)).to be(false)
    end

    it 'returns false when email already exists' do
      allow(self).to receive(:createPasswordHash).and_return('hashed_secret')
      allow(self).to receive(:userExists).with(db, 'alice').and_return(false)
      allow(self).to receive(:emailExists).with(db, 'alice@example.com').and_return(true)

      expect(db).not_to receive(:query)
      expect(createUser('alice', 'secret', 'alice@example.com', db)).to be(false)
    end

    it 'escapes special characters before insertion (edge case)' do
      allow(self).to receive(:createPasswordHash).and_return('h')
      allow(self).to receive(:userExists).and_return(false)
      allow(self).to receive(:emailExists).and_return(false)
      allow(db).to receive(:escape) { |value| value.gsub("'", "\\\\'") }

      expect(db).to receive(:query).with("INSERT INTO Users (usr_name, pswd, email) VALUES ('o\\\\'hara', 'h', 'o\\\\'hara@example.com');")

      expect(createUser("o'hara", 'pw', "o'hara@example.com", db)).to be(true)
    end
  end

  describe '#verifyPassword' do
    it 'returns true for a valid password' do
      hash = BCrypt::Password.create('secret').to_s
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).with("SELECT pswd FROM Users WHERE usr_name = 'alice';").and_return([{ 'pswd' => hash }])

      expect(verifyPassword('secret', 'alice', db)).to be(true)
    end

    it 'returns false for an invalid password' do
      hash = BCrypt::Password.create('secret').to_s
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).with("SELECT pswd FROM Users WHERE usr_name = 'alice';").and_return([{ 'pswd' => hash }])

      expect(verifyPassword('wrong', 'alice', db)).to be(false)
    end

    it 'returns false when user is not found (edge case)' do
      allow(db).to receive(:escape).with('missing_user').and_return('missing_user')
      allow(db).to receive(:query).with("SELECT pswd FROM Users WHERE usr_name = 'missing_user';").and_return([])

      expect(verifyPassword('secret', 'missing_user', db)).to be(false)
    end
  end

  describe '#signIn' do
    it 'returns true when verifyPassword succeeds' do
      allow(self).to receive(:verifyPassword).with('secret', 'alice', db).and_return(true)
      expect(signIn('alice', 'secret', db)).to be(true)
    end

    it 'returns false when verifyPassword fails' do
      allow(self).to receive(:verifyPassword).with('wrong', 'alice', db).and_return(false)
      expect(signIn('alice', 'wrong', db)).to be(false)
    end
  end

  describe '#userExists' do
    it 'returns true when count is greater than zero' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).with("SELECT COUNT(*) AS count FROM Users WHERE usr_name = 'alice';").and_return([{ 'count' => 1 }])

      expect(userExists(db, 'alice')).to be(true)
    end

    it 'returns false when count is zero' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).with("SELECT COUNT(*) AS count FROM Users WHERE usr_name = 'alice';").and_return([{ 'count' => 0 }])

      expect(userExists(db, 'alice')).to be(false)
    end

    it 'returns false when query result is empty (edge case)' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).with("SELECT COUNT(*) AS count FROM Users WHERE usr_name = 'alice';").and_return([])

      expect(userExists(db, 'alice')).to be(false)
    end
  end

  describe '#emailExists' do
    it 'returns true when count is greater than zero' do
      allow(db).to receive(:escape).with('alice@example.com').and_return('alice@example.com')
      allow(db).to receive(:query).with("SELECT COUNT(*) AS count FROM Users WHERE email = 'alice@example.com';").and_return([{ 'count' => 1 }])

      expect(emailExists(db, 'alice@example.com')).to be(true)
    end

    it 'returns false when count is zero' do
      allow(db).to receive(:escape).with('alice@example.com').and_return('alice@example.com')
      allow(db).to receive(:query).with("SELECT COUNT(*) AS count FROM Users WHERE email = 'alice@example.com';").and_return([{ 'count' => 0 }])

      expect(emailExists(db, 'alice@example.com')).to be(false)
    end

    it 'returns false when query result is empty (edge case)' do
      allow(db).to receive(:escape).with('alice@example.com').and_return('alice@example.com')
      allow(db).to receive(:query).with("SELECT COUNT(*) AS count FROM Users WHERE email = 'alice@example.com';").and_return([])

      expect(emailExists(db, 'alice@example.com')).to be(false)
    end
  end
end
