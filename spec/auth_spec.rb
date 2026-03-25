#spec/auth_spec.rb
require_relative '../backend/authenication'

#my first test
describe '#createPasswordHash' do
  it 'returns a bcrypt hash' do
    result = createPasswordHash('password')
    expect(BCrypt::Password.new(result)).to eq('password')
  end
end

# spec/auth_spec.rb
require 'spec_helper'
require 'bcrypt'
require_relative '../backend/authenication'

#using co pilots /tests generation
RSpec.describe 'authenication helpers' do
  describe '#createPasswordHash' do
    it 'returns a bcrypt hash matching the original password' do
      result = createPasswordHash('password')
      expect(BCrypt::Password.new(result)).to eq('password')
    end

    it 'hashes an empty string' do
      result = createPasswordHash('')
      expect(BCrypt::Password.new(result)).to eq('')
    end

    it 'raises for nil input' do
      expect { createPasswordHash(nil) }.to raise_error(TypeError)
    end
  end

  describe '#userExists' do
    let(:db) { instance_double('Mysql2::Client') }

    it 'returns true when count is greater than 0' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).and_return([{ 'count' => 1 }])

      expect(userExists(db, 'alice')).to be(true)
    end

    it 'returns false when count is 0' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).and_return([{ 'count' => 0 }])

      expect(userExists(db, 'alice')).to be(false)
    end

    it 'returns false when query result is nil' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).and_return([])

      expect(userExists(db, 'alice')).to be(false)
    end
  end

  describe '#emailExists' do
    let(:db) { instance_double('Mysql2::Client') }

    it 'returns true when count is greater than 0' do
      allow(db).to receive(:escape).with('a@b.com').and_return('a@b.com')
      allow(db).to receive(:query).and_return([{ 'count' => 1 }])

      expect(emailExists(db, 'a@b.com')).to be(true)
    end

    it 'returns false when count is 0' do
      allow(db).to receive(:escape).with('a@b.com').and_return('a@b.com')
      allow(db).to receive(:query).and_return([{ 'count' => 0 }])

      expect(emailExists(db, 'a@b.com')).to be(false)
    end

    it 'returns false when query result is nil' do
      allow(db).to receive(:escape).with('a@b.com').and_return('a@b.com')
      allow(db).to receive(:query).and_return([])

      expect(emailExists(db, 'a@b.com')).to be(false)
    end
  end

  describe '#createUser' do
    let(:db) { instance_double('Mysql2::Client') }

    it 'returns true and inserts when username/email are new' do
      allow(self).to receive(:createPasswordHash).with('secret').and_return('hashed_secret')
      allow(self).to receive(:userExists).with(db, 'alice').and_return(false)
      allow(self).to receive(:emailExists).with(db, 'alice@example.com').and_return(false)
      allow(db).to receive(:escape) { |v| "esc_#{v}" }

      expect(db).to receive(:query).with(
        "INSERT INTO Users (usr_name, pswd, email) VALUES ('esc_alice', 'esc_hashed_secret', 'esc_alice@example.com');"
      )

      expect(createUser('alice', 'secret', 'alice@example.com', db)).to be(true)
    end

    it 'returns false when username already exists' do
      allow(self).to receive(:createPasswordHash).with('secret').and_return('hashed_secret')
      allow(self).to receive(:userExists).with(db, 'alice').and_return(true)
      allow(self).to receive(:emailExists)

      expect(db).not_to receive(:query)
      expect(createUser('alice', 'secret', 'alice@example.com', db)).to be(false)
      expect(self).not_to have_received(:emailExists)
    end

    it 'returns false when email already exists' do
      allow(self).to receive(:createPasswordHash).with('secret').and_return('hashed_secret')
      allow(self).to receive(:userExists).with(db, 'alice').and_return(false)
      allow(self).to receive(:emailExists).with(db, 'alice@example.com').and_return(true)

      expect(db).not_to receive(:query)
      expect(createUser('alice', 'secret', 'alice@example.com', db)).to be(false)
    end
  end

  describe '#verifyPassword' do
    let(:db) { instance_double('Mysql2::Client') }
    let(:hash) { BCrypt::Password.create('secret').to_s }

    it 'returns true when password matches' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).and_return([{ 'pswd' => hash }])

      expect(verifyPassword('secret', 'alice', db)).to be(true)
    end

    it 'returns false when password does not match' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).and_return([{ 'pswd' => hash }])

      expect(verifyPassword('wrong', 'alice', db)).to be(false)
    end

    it 'raises when user row is missing' do
      allow(db).to receive(:escape).with('alice').and_return('alice')
      allow(db).to receive(:query).and_return([])

      expect { verifyPassword('secret', 'alice', db) }.to raise_error(NoMethodError)
    end
  end

  describe '#signIn' do
    let(:db) { instance_double('Mysql2::Client') }

    it 'returns true when verifyPassword is true' do
      expect(self).to receive(:verifyPassword).with('secret', 'alice', db).and_return(true)
      expect(signIn('alice', 'secret', db)).to be(true)
    end

    it 'returns false when verifyPassword is false' do
      expect(self).to receive(:verifyPassword).with('wrong', 'alice', db).and_return(false)
      expect(signIn('alice', 'wrong', db)).to be(false)
    end
  end
end