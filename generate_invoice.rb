# Install the prawn gem before running this script:
# gem install prawn

require 'prawn'
require 'csv'
require 'fileutils'

class Invoice
  attr_accessor :invoice_number, :date, :client_name, :services

  def initialize(invoice_number, date, client_name)
    @invoice_number = invoice_number
    @date = date
    @client_name = client_name
    @services = []
  end

  def add_service(description, quantity, rate)
    @services << { description: description, quantity: quantity, rate: rate }
  end

  def generate_pdf
    pdf = Prawn::Document.new

    pdf.text "------------------------------------", align: :center
    pdf.text "           INVOICE #{invoice_number}", align: :center
    pdf.text "------------------------------------", align: :center
    pdf.text "Date: #{date}", align: :center
    pdf.text "Client: #{client_name}", align: :center
    pdf.text "------------------------------------", align: :center

    services.each do |service|
      pdf.text "#{service[:description]} | #{service[:quantity]} | $#{service[:rate]} | $#{service[:quantity] * service[:rate]}", align: :center
    end

    pdf.text "------------------------------------", align: :center
    total_amount = services.map { |s| s[:quantity] * s[:rate] }.sum
    pdf.text "Total Amount Due: $#{total_amount}", align: :center
    pdf.text "------------------------------------", align: :center

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
# Check if the current file is being run as the main program
if __FILE__ == $PROGRAM_NAME
  csv_file = 'Data/invoicedata.csv'
  invoice_data = load_data_from_csv(csv_file)

  invoice_data.each do |data|
    invoice = Invoice.new(data['InvoiceNumber'], data['Date'], data['ClientName'])
    invoice.add_service(data['Description'], data['Quantity'].to_i, data['Rate'].to_f)
    invoice.generate_pdf
  end

  puts "PDF invoices generated successfully."
end
