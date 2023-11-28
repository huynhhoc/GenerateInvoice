require 'pg'
require 'prawn'

def create_tables(conn)
  # Create company_info table
  conn.exec(<<-SQL)
    CREATE TABLE IF NOT EXISTS company_info (
      id SERIAL PRIMARY KEY,
      company_name VARCHAR(255),
      street VARCHAR(255),
      city_state_country VARCHAR(255),
      zipcode VARCHAR(10),
      email VARCHAR(255)
    );
  SQL

  # Create index for company_info
  conn.exec('CREATE INDEX IF NOT EXISTS idx_company_name ON company_info(company_name);')

  # Create client_info table
  conn.exec(<<-SQL)
    CREATE TABLE IF NOT EXISTS client_info (
      id SERIAL PRIMARY KEY,
      invoice_number VARCHAR(20) UNIQUE,
      date DATE,
      customer_id VARCHAR(20),
      name VARCHAR(255),
      street VARCHAR(255),
      city_state_country VARCHAR(255),
      phone VARCHAR(20)
    );
  SQL

  # Create index for client_info
  conn.exec('CREATE INDEX IF NOT EXISTS idx_invoice_number ON client_info(invoice_number);')

  # Check if the unique constraint on invoice_number exists before creating it
  result = conn.exec(<<-SQL)
    SELECT constraint_name
    FROM information_schema.table_constraints
    WHERE table_name = 'client_info' AND constraint_type = 'UNIQUE' AND constraint_name = 'uq_invoice_number';
  SQL

  # If the constraint doesn't exist, add it
  if result.ntuples.zero?
    conn.exec(<<-SQL)
      ALTER TABLE client_info
      ADD CONSTRAINT uq_invoice_number UNIQUE (invoice_number);
    SQL
  end

  # Create products table
  conn.exec(<<-SQL)
    CREATE TABLE IF NOT EXISTS products (
      id SERIAL PRIMARY KEY,
      description VARCHAR(255),
      rate DECIMAL
    );
  SQL

  # Create index for products
  conn.exec('CREATE INDEX IF NOT EXISTS idx_description ON products(description);')

  # Create invoice_details table
  conn.exec(<<-SQL)
    CREATE TABLE IF NOT EXISTS invoice_details (
      id SERIAL PRIMARY KEY,
      invoice_number VARCHAR(20),
      product_id INTEGER,
      quantity INTEGER,
      FOREIGN KEY (invoice_number) REFERENCES client_info (invoice_number),
      FOREIGN KEY (product_id) REFERENCES products (id)
    );
  SQL

  # Create indexes for invoice_details
  conn.exec('CREATE INDEX IF NOT EXISTS idx_invoice_number ON invoice_details(invoice_number);')
  conn.exec('CREATE INDEX IF NOT EXISTS idx_product_id ON invoice_details(product_id);')
end


def load_data_into_tables(conn)
  # Example Company Information
  company_info = {
    company_name: "Huynh Hoc",
    street: "123 Main Street",
    city_state_country: "City, State, Country",
    zipcode: "12345",
    email: "huynhhoc@gmail.com"
  }

  # Insert company_info into the database
  conn.exec_params(
    'INSERT INTO company_info (company_name, street, city_state_country, zipcode, email) VALUES ($1, $2, $3, $4, $5)',
    [company_info[:company_name], company_info[:street], company_info[:city_state_country], company_info[:zipcode], company_info[:email]]
  )

  # Example Client Information
  client_info = {
    invoice_number: '2023001',
    date: '2023-11-28',
    customer_id: '12345',
    name: 'Client XYZ',
    street: '456 Client Street',
    city_state_country: 'Client City, State, Country',
    phone: '9876543210'
  }

  # Insert client_info into the database
  conn.exec_params(
    'INSERT INTO client_info (invoice_number, date, customer_id, name, street, city_state_country, phone) VALUES ($1, $2, $3, $4, $5, $6, $7)',
    [client_info[:invoice_number], client_info[:date], client_info[:customer_id], client_info[:name], client_info[:street], client_info[:city_state_country], client_info[:phone]]
  )

  # Example Product Information
  products_info = [
    { description: 'Construction Work', rate: 1000 },
    { description: 'Material Supply', rate: 500 },
    { description: 'Consulting Services', rate: 1200 }
  ]

  # Insert products_info into the database
  products_info.each do |product_info|
    conn.exec_params(
      'INSERT INTO products (description, rate) VALUES ($1, $2)',
      [product_info[:description], product_info[:rate]]
    )
  end

  # Example Invoice Details
  invoice_details = [
    {invoice_number: '2023001', product_id: 1, quantity: 5},
    {invoice_number: '2023001', product_id: 2, quantity: 3}
  ]

  # Insert invoice_details into the database
  invoice_details.each do |detail|
    conn.exec_params(
      'INSERT INTO invoice_details (invoice_number, product_id, quantity) VALUES ($1, $2, $3)',
      [detail[:invoice_number], detail[:product_id], detail[:quantity]]
    )
  end
end

def main
  # Connect to the PostgreSQL database
  conn = PG.connect(dbname: 'invoice_app', user: 'postgres', password: '123456')

  # Create tables if they do not exist
  create_tables(conn)

  # Load data into tables
  load_data_into_tables(conn)

  # Disconnect from the PostgreSQL database
  conn.close
end

# Check if the current file is being run as the main program
if __FILE__ == $PROGRAM_NAME
  # Execute the main function
  main
end
