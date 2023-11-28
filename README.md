# Invoice Generation System
## Overview

This project provides scripts to set up a PostgreSQL database for an invoice generation system and generate PDF invoices for specified invoice numbers.

## Prerequisites

    * PostgreSQL installed and running.
    * Ruby installed.

## Setup

1. Database Configuration
* Ensure PostgreSQL is running.
* Update the PostgreSQL database connection details (dbname, user, password) in the script files (create_table_and_sampledata.rb and main.rb).

2. Create Tables and Populate Sample Data

Run the create_table_and_sampledata.rb script to create necessary tables and populate them with sample data.

```
ruby create_table_and_sampledata.rb

```
## Generate PDF Invoices

Run the main.rb script to generate PDF invoices for specified invoice numbers.

```
ruby main.rb

```    
Replace 2023001 with the desired invoice number in the main.rb script.

## Project Structure

1. Utils Folder
    * utils.rb: Contains utility functions for database operations.
    * invoice.rb: Defines the Invoice class for generating PDF invoices.

2. Scripts
    * create_table_and_sampledata.rb: Creates tables and populates sample data.
    * main.rb: Generates PDF invoices for specified invoice numbers.

## Error Handling

    Duplicate Key Violation: If you encounter a duplicate key violation error, the scripts include error handling to notify you and suggest handling options.

## Additional Notes

    Customize the invoice generation logic, payment terms, and other details in the scripts based on your requirements.

    Feel free to extend the functionality of the Invoice class or add more utility functions to suit your needs.