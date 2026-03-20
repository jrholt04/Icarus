#File: dbTools.rb
# A Flynn, E Kendall, J Holt, Transy U
# CS 4444, Winter 2025
# 
#   This file contains functions for describing the database structure and backing up the database. The describeDatabase function provides an overview of the database, including the number of tables and 
#   estimated total rows. The describeAllTables function gives detailed information about each table and its columns. The backupDatabase function is a placeholder for future implementation of database backup functionality.
#
#
require 'mysql2'
require 'stringio'

require_relative '../env_loader'

icarusDB = Mysql2::Client.new(:host => ENV.fetch('ICARUS_DB_HOST'), :username => ENV.fetch('ICARUS_DB_USER'), :password => ENV.fetch('ICARUS_DB_PASSWORD'), :database => ENV.fetch('ICARUS_DB_NAME'))

# Function to describe the database structure, including the number of tables and estimated total rows. It queries the information_schema to gather this information and formats it into a readable string.
def describeDatabase(db)
	databaseNameRow = db.query("SELECT DATABASE() AS db_name;").first
	databaseName = databaseNameRow ? databaseNameRow['db_name'] : ''

	tableCountRow = db.query("SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = '#{db.escape(databaseName)}';").first
	tableCount = tableCountRow ? tableCountRow['table_count'] : 0

	tableRows = db.query("SELECT TABLE_NAME AS table_name, TABLE_ROWS AS table_rows FROM information_schema.tables WHERE table_schema = '#{db.escape(databaseName)}' ORDER BY TABLE_NAME;")

	totalRows = 0
	tableLines = []
	tableRows.each do |table|
		tableName = table['table_name']
		next if tableName.nil?
		rows = table['table_rows'] || 0
		totalRows += rows
		tableLines << "- #{tableName}: #{rows} rows"
	end

	description = "Database: #{databaseName}\n"
	description += "Table count: #{tableCount}\n"
	description += "Estimated total rows: #{totalRows}\n"
	description += "Tables:\n"
	description += tableLines.join("\n")

	return description
end

# Function to describe all tables in the database, including detailed information about each table and its columns. It queries the information_schema to get the list of tables and their columns, and formats this information into a readable string.
def describeAllTables(db)
	databaseNameRow = db.query("SELECT DATABASE() AS db_name;").first
	databaseName = databaseNameRow ? databaseNameRow['db_name'] : ''

	tableRows = db.query("SELECT TABLE_NAME AS table_name FROM information_schema.tables WHERE table_schema = '#{db.escape(databaseName)}' ORDER BY TABLE_NAME;")

	sections = []
	tableRows.each do |table|
		tableName = table['table_name']
		next if tableName.nil?
		escapedTableName = tableName.gsub('`', '``')
		columns = db.query("SHOW COLUMNS FROM `#{escapedTableName}`;")

		columnLines = []
		columns.each do |column|
			columnLines << "  - #{column['Field']} | #{column['Type']} | null: #{column['Null']} | key: #{column['Key']} | default: #{column['Default'].nil? ? 'NULL' : column['Default']} | extra: #{column['Extra']}"
		end

		section = "Table: #{tableName}\n"
		section += "Columns:\n"
		section += columnLines.join("\n")
		sections << section
	end

	return sections.join("\n\n")
end

# Function to backup the database. This is a placeholder for future implementation of database backup functionality.
def backupDatabase(db)
	
end
