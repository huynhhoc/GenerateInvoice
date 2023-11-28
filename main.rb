# main.rb

require_relative 'Utils/utils'
require_relative 'Utils/invoice'

def main(invoice_number)
    # Connect to the PostgreSQL database
    conn = PG.connect(dbname: 'invoice_app', user: 'postgres', password: '123456')
    company_info = Utils.load_company_info(conn)
    
    # Fetch invoice data for the specified invoice number
    invoice_data = Utils.load_invoice_data(conn, invoice_number)
  
    # Check if the invoice data is not nil
    if invoice_data
      # Create an instance of Invoice
      invoice = Invoice.new(invoice_data[:client_info][:invoice_number], invoice_data[:client_info][:date], invoice_data[:client_info][:name])
  
      # Add services
      invoice_data[:products].each do |product_data|
        invoice.add_service(product_data[:description], product_data[:quantity], product_data[:rate])
      end
  
      # Set client information
      invoice.set_client_info(invoice_data[:client_info])
  
      # Set company information
      invoice.set_company_info(company_info)
  
      # Set other information
      other_info = {
        payment_days: 30,
        special_instructions: "Please make the payment by the due date."
      }
      invoice.set_other_info(other_info)
  
      # Generate PDF
      invoice.generate_pdf
  
      puts "PDF invoices generated successfully."
    else
      puts "Invoice data not found for invoice number #{invoice_number}."
    end
  end
  
  # Check if the current file is being run as the main program
  if __FILE__ == $PROGRAM_NAME
    # Specify the invoice number you want to generate
    invoice_number = '2023001'
  
    # Execute the main function
    main(invoice_number)
  end
