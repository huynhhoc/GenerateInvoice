# Install the prawn gem before running this script:
# gem install prawn

require 'prawn'

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

    pdf.render_file("invoice_#{invoice_number}.pdf")
  end
end

# Example usage:
invoice = Invoice.new("2023001", "2023-11-28", "Client XYZ")
invoice.add_service("Construction Work", 5, 1000)
invoice.add_service("Material Supply", 10, 500)
invoice.generate_pdf

puts "PDF invoice generated successfully."
