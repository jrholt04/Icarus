require 'spec_helper'
require_relative '../backend/search'

RSpec.describe 'search helpers' do
  describe '#findBooks' do
    let(:db) { instance_double('Mysql2::Client') }

    it 'queries Books by title and returns rows on success' do
      rows = [{ 'id' => 1, 'title' => 'Dune' }]
      expect(db).to receive(:query)
        .with("SELECT * FROM Books WHERE title LIKE '%Dune%';")
        .and_return(rows)

      expect(findBooks(db, 'Dune')).to eq(rows)
    end

    it 'propagates database errors' do
      allow(db).to receive(:query).and_raise(StandardError, 'db error')

      expect { findBooks(db, 'Dune') }.to raise_error(StandardError, 'db error')
    end

    it 'handles nil search term as empty string' do
      expect(db).to receive(:query)
        .with("SELECT * FROM Books WHERE title LIKE '%%';")
        .and_return([])

      expect(findBooks(db, nil)).to eq([])
    end

    it 'handles empty string search term' do
      expect(db).to receive(:query)
        .with("SELECT * FROM Books WHERE title LIKE '%%';")
        .and_return([])

      expect(findBooks(db, '')).to eq([])
    end

    it 'coerces non-string input using to_s' do
      expect(db).to receive(:query)
        .with("SELECT * FROM Books WHERE title LIKE '%123%';")
        .and_return([])

      expect(findBooks(db, 123)).to eq([])
    end

    it 'passes special characters through to SQL string (edge case)' do
      payload = "' OR 1=1 --"
      expected_query = "SELECT * FROM Books WHERE title LIKE '%#{payload}%';"

      expect(db).to receive(:query).with(expected_query).and_return([])
      expect(findBooks(db, payload)).to eq([])
    end
  end

  describe '#findAuthors' do
    let(:db) { instance_double('Mysql2::Client') }

    it 'queries Authors by name and returns rows on success' do
      rows = [{ 'id' => 2, 'name' => 'Frank Herbert' }]
      expect(db).to receive(:query)
        .with("SELECT * FROM Authors WHERE name LIKE '%Frank%';")
        .and_return(rows)

      expect(findAuthors(db, 'Frank')).to eq(rows)
    end

    it 'propagates database errors' do
      allow(db).to receive(:query).and_raise(StandardError, 'db error')

      expect { findAuthors(db, 'Frank') }.to raise_error(StandardError, 'db error')
    end

    it 'handles nil search term as empty string' do
      expect(db).to receive(:query)
        .with("SELECT * FROM Authors WHERE name LIKE '%%';")
        .and_return([])

      expect(findAuthors(db, nil)).to eq([])
    end

    it 'handles empty string search term' do
      expect(db).to receive(:query)
        .with("SELECT * FROM Authors WHERE name LIKE '%%';")
        .and_return([])

      expect(findAuthors(db, '')).to eq([])
    end

    it 'coerces non-string input using to_s' do
      expect(db).to receive(:query)
        .with("SELECT * FROM Authors WHERE name LIKE '%456%';")
        .and_return([])

      expect(findAuthors(db, 456)).to eq([])
    end

    it 'passes quote characters through to SQL string (edge case)' do
      term = "O'Reilly"
      expected_query = "SELECT * FROM Authors WHERE name LIKE '%#{term}%';"

      expect(db).to receive(:query).with(expected_query).and_return([])
      expect(findAuthors(db, term)).to eq([])
    end
  end
end