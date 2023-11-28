require 'prawn'
require 'csv'
require 'fileutils'

class Invoice
  attr_accessor :invoice_number, :date, :client_name, :services, :company_info, :client_info, :invoice_total, :other_info
  
  def initialize(invoice_number, date, client_name)
    @invoice_number = invoice_number
    @date = date
    @client_name = client_name
    @services = []
    @company_info = {}
    @client_info = {}
    @invoice_total = 0
    @other_info = {}
  end

  def add_service(description, quantity, rate)
    @services << { description: description, quantity: quantity, rate: rate }
    @invoice_total += quantity * rate
  end

  def set_company_info(info)
    @company_info = info
  end

  def set_client_info(info)
    @client_info = info
  end

  def set_invoice_total(total)
    @invoice_total = total
  end

  def set_other_info(info)
    @other_info = info
  end

  def generate_pdf
    pdf = Prawn::Document.new

    # Section 1: Company Information
    pdf.text "INVOICE BUILDING", align: :center, size: 20, style: :bold
    pdf.text "#{company_info[:company_name]} Logo of Company", align: :center
    pdf.move_down 10
    pdf.text "Street: #{company_info[:street]}"
    pdf.text "City, State, Country: #{company_info[:city_state_country]}"
    pdf.text "Zipcode: #{company_info[:zipcode]}"
    pdf.text "Email: #{company_info[:email]}"
    pdf.move_down 20

    # Section 2: Bill To (Client Information)
    pdf.draw_text("BILL TO", at: [10, pdf.cursor], size: 16, style: :bold)
    pdf.draw_text("Invoice Number: #{client_info[:invoice_number]}", at: [10, pdf.cursor - 10])
    pdf.draw_text("Date: #{client_info[:date]}", at: [10, pdf.cursor - 20])
    pdf.draw_text("Customer ID: #{client_info[:customer_id]}", at: [10, pdf.cursor - 30])

    # Client Information in the Right Column
    right_column_y = pdf.cursor
    pdf.draw_text("Name: #{client_info[:name]}", at: [250, right_column_y])
    pdf.draw_text("Street: #{client_info[:street]}", at: [250, right_column_y - 10])
    pdf.draw_text("City, State, Country: #{client_info[:city_state_country]}", at: [250, right_column_y - 20])
    pdf.draw_text("Phone: #{client_info[:phone]}", at: [250, right_column_y - 30])

    # Section 3: Details
    pdf.move_down 50
    pdf.text "Details", size: 16, style: :bold
    pdf.move_down 25
    pdf.draw_text("No.", at: [10, pdf.cursor - 5], style: :bold)
    pdf.move_down 25
    pdf.draw_text("Service/Products", at: [50, pdf.cursor - 5], style: :bold)
    pdf.draw_text("Description", at: [170, pdf.cursor - 5], style: :bold)
    pdf.draw_text("Quantity", at: [300, pdf.cursor - 5], style: :bold)
    pdf.draw_text("Amount", at: [400, pdf.cursor - 5], style: :bold)

    line_spacing = 25

    services.each_with_index do |service, index|
      pdf.draw_text("#{index + 1}", at: [10, pdf.cursor - line_spacing])
      pdf.draw_text("#{service[:description]}", at: [50, pdf.cursor - line_spacing])
      pdf.draw_text("", at: [170, pdf.cursor - line_spacing])  # You can add description here if needed
      pdf.draw_text("#{service[:quantity]}", at: [300, pdf.cursor - line_spacing])
      pdf.draw_text("$#{service[:quantity] * service[:rate]}", at: [400, pdf.cursor - line_spacing])
      pdf.move_down line_spacing
    end
    pdf.move_down line_spacing
    # Last row: Total amount
    pdf.draw_text("", at: [10, pdf.cursor - 10])
    pdf.draw_text("", at: [50, pdf.cursor - 10])
    pdf.draw_text("", at: [170, pdf.cursor - 10])
    pdf.draw_text("Total", at: [300, pdf.cursor - 10], style: :bold)
    pdf.draw_text("$#{invoice_total}", at: [400, pdf.cursor - 10], style: :bold)

    # Section 4: Other Information
    pdf.move_down 20
    pdf.text "Other Information", size: 16, style: :bold
    pdf.text "Payment is due within #{other_info[:payment_days]} days"
    pdf.text "Comments or Special instructions: #{other_info[:special_instructions]}"

    # Save PDF
    output_folder = 'Invoices'
    FileUtils.mkdir_p(output_folder) unless File.directory?(output_folder)

    pdf.render_file(File.join(output_folder, "invoice_#{invoice_number}.pdf"))
  end
end

def load_data_from_csv(csv_file)
  data = []
  CSV.foreach(csv_file, headers: true) do |row|
    data << row.to_h
  end
  data
end

# Example usage:
csv_file = 'Data/invoicedata.csv'
invoice_data = load_data_from_csv(csv_file)

# Example Company Information
company_info = {
  company_name: "Your Company",
  street: "123 Main Street",
  city_state_country: "City, State, Country",
  zipcode: "12345",
  email: "info@yourcompany.com"
}

invoice_data.each do |data|
  # Create an instance of Invoice
  invoice = Invoice.new(data['InvoiceNumber'], data['Date'], data['ClientName'])

  # Add services
  services_data = invoice_data.select { |item| item['InvoiceNumber'] == data['InvoiceNumber'] }
  services_data.each do |service_data|
    invoice.add_service(service_data['Description'], service_data['Quantity'].to_i, service_data['Rate'].to_f)
  end

  # Set client information
  client_info = {
    invoice_number: data['InvoiceNumber'],
    date: data['Date'],
    customer_id: "12345",  # You can replace this with the actual customer ID
    name: data['ClientName'],
    street: "456 Client Street",  # Replace with the client's actual street address
    city_state_country: "Client City, State, Country",  # Replace with the client's actual city, state, and country
    phone: "9876543210"  # Replace with the client's actual phone number
  }
  invoice.set_client_info(client_info)

  # Set company information
  invoice.set_company_info(company_info)

  # Set other information
  other_info = {
    payment_days: 30,  # Replace with the actual payment terms
    special_instructions: "Please make the payment by the due date."
  }
  invoice.set_other_info(other_info)

  # Generate PDF
  invoice.generate_pdf
end

puts "PDF invoices generated successfully."