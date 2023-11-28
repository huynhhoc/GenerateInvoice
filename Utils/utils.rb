# utils.rb

require 'pg'
require 'prawn'

module Utils
  def self.create_tables(conn)
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

  def self.load_sampledata_into_tables(conn)
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

  def self.load_company_info(conn)
    result = conn.exec('SELECT * FROM company_info LIMIT 1')
    if result.ntuples.positive?
        {
        company_name: result[0]['company_name'],
        street: result[0]['street'],
        city_state_country: result[0]['city_state_country'],
        zipcode: result[0]['zipcode'],
        email: result[0]['email']
        }
    else
        # Return default values if company_info doesn't exist in the database
        {
        company_name: "Your Company",
        street: "123 Main Street",
        city_state_country: "City, State, Country",
        zipcode: "12345",
        email: "info@yourcompany.com"
        }
    end
  end

  def self.load_invoice_data(conn, invoice_number)
    # Fetch client_info from the database
    client_info_result = conn.exec_params('SELECT * FROM client_info WHERE invoice_number = $1', [invoice_number])

    # Fetch products related to the invoice from the database
    products_result = conn.exec_params(
        'SELECT products.*, invoice_details.quantity
        FROM products
        JOIN invoice_details ON products.id = invoice_details.product_id
        WHERE invoice_details.invoice_number = $1',
        [invoice_number]
    )

    # Process the results and construct the invoice data hash
    invoice_data = {}

    if client_info_result.ntuples.positive?
        invoice_data[:client_info] = {
        invoice_number: client_info_result[0]['invoice_number'],
        date: client_info_result[0]['date'],
        customer_id: client_info_result[0]['customer_id'],
        name: client_info_result[0]['name'],
        street: client_info_result[0]['street'],
        city_state_country: client_info_result[0]['city_state_country'],
        phone: client_info_result[0]['phone']
        }
    else
        # Return nil or handle the case when client_info is not found
        return nil
    end

    # Fetch and process products data
    products_data = products_result.map do |product_row|
        {
        description: product_row['description'],
        rate: product_row['rate'].to_f, # Ensure rate is converted to float
        quantity: product_row['quantity'].to_i # Ensure quantity is converted to integer
        }
    end

    invoice_data[:products] = products_data unless products_data.empty?

    invoice_data
  end

  def self.load_client_info(conn, invoice_number)
    result = conn.exec_params('SELECT * FROM client_info WHERE invoice_number = $1', [invoice_number])

    if result.ntuples.positive?
        client_info = {
        invoice_number: result[0]['invoice_number'],
        date: result[0]['date'],
        customer_id: result[0]['customer_id'],
        name: result[0]['name'],
        street: result[0]['street'],
        city_state_country: result[0]['city_state_country'],
        phone: result[0]['phone']
        }
        client_info
    else
        # Return nil or handle the case when client_info is not found
        nil
    end
  end
end
