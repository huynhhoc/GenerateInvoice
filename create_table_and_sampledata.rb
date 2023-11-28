require 'pg'
require 'prawn'
require_relative 'Utils/utils'

def main
  # Connect to the PostgreSQL database
  conn = PG.connect(dbname: 'invoice_app', user: 'postgres', password: '123456')

  begin
    # Create tables if they do not exist
    Utils.create_tables(conn)

    # Load data into tables
    Utils.load_sampledata_into_tables(conn)

  rescue PG::UniqueViolation => e
    # Handle the unique violation error
    puts "Error: #{e.message}"
    puts "You might want to handle the duplicate key violation here."

  ensure
    # Disconnect from the PostgreSQL database
    conn.close
  end
end

# Check if the current file is being run as the main program
if __FILE__ == $PROGRAM_NAME
  # Execute the main function
  main
end
