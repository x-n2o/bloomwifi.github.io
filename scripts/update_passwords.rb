#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'csv'
require 'date'
require 'fileutils'

# Google Sheets CSV export URL
SHEET_ID = '13G1JKaLiD1rqrGp8rTGW5F14nfoBkfdbRpHar4J7_tk'
GID = '1635679974'
CSV_URL = "https://docs.google.com/spreadsheets/d/#{SHEET_ID}/export?format=csv&gid=#{GID}"

# Post template
POST_TEMPLATE = <<~TEMPLATE
  ---
  layout: post
  password: %{password}
  ---
  <h3>{{ page.date | date: "%%%%A, %%%%B %%%%e, %%%%Y" }}</h3>
  <h1 id="password" onclick="copyToClipboard()" style="cursor: pointer; color: #007bff;">{{ page.password }} <i class="fas fa-copy"></i></h1>
  {% qr WIFI:T:WPA;S:Bloom Guest;P:%{password}; %}

  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">

  <style>
  #password:hover {
    color: #0056b3;
  }
  #password i {
    margin-left: 5px;
    font-size: 0.9em;
  }
  </style>

  <script>
  function copyToClipboard() {
    navigator.clipboard.writeText('{{ page.password }}');
    const password = document.getElementById('password');
    const originalHTML = password.innerHTML;
    password.innerHTML = '{{ page.password }} <i class="fas fa-check"></i>';
    password.style.color = '#28a745';
    
    setTimeout(() => {
      password.innerHTML = originalHTML;
      password.style.color = '#007bff';
    }, 2000);
  }
  </script>
TEMPLATE

def fetch_csv_data
  uri = URI(CSV_URL)
  
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    
    # Follow redirects
    case response
    when Net::HTTPRedirection
      redirect_uri = URI(response['location'])
      redirect_response = Net::HTTP.get_response(redirect_uri)
      
      unless redirect_response.is_a?(Net::HTTPSuccess)
        puts "Error fetching CSV: #{redirect_response.code} #{redirect_response.message}"
        exit 1
      end
      
      redirect_response.body
    when Net::HTTPSuccess
      response.body
    else
      puts "Error fetching CSV: #{response.code} #{response.message}"
      exit 1
    end
  end
end

def parse_passwords(csv_data)
  passwords = {}
  
  puts "\nDEBUG: First 500 chars of CSV:"
  puts csv_data[0...500]
  puts "\n"
  
  lines = csv_data.split("\n")
  headers = lines[0].split(',').map(&:strip)
  puts "DEBUG: Headers: #{headers.inspect}"
  
  lines[1..-1].each_with_index do |line, idx|
    next if line.strip.empty?
    
    fields = line.split(',').map(&:strip)
    next if fields.size < 2
    
    date_str = fields[0]
    password = fields[1]
    
    puts "DEBUG: Row #{idx + 1} - Date: '#{date_str}', Password: '#{password}'"
    
    next if date_str.nil? || password.nil? || password.empty?
    
    begin
      date = Date.parse(date_str)
      passwords[date] = password
    rescue Date::Error => e
      puts "Warning: Invalid date format '#{date_str}': #{e.message}"
    end
  end
  
  passwords
end

def create_post(date, password)
  posts_dir = File.join(__dir__, '..', '_posts')
  FileUtils.mkdir_p(posts_dir)
  
  filename = "#{date.strftime('%Y-%m-%d')}-wifi.md"
  filepath = File.join(posts_dir, filename)
  
  content = <<~CONTENT
    ---
    layout: post
    password: #{password}
    ---
    <h3>{{ page.date | date: "%A, %B %e, %Y" }}</h3>
    <h1 id="password" onclick="copyToClipboard()" style="cursor: pointer; color: #007bff;">{{ page.password }} <i class="fas fa-copy"></i></h1>
    {% qr WIFI:T:WPA;S:Bloom Guest;P:#{password}; %}

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">

    <style>
    #password:hover {
      color: #0056b3;
    }
    #password i {
      margin-left: 5px;
      font-size: 0.9em;
    }
    </style>

    <script>
    function copyToClipboard() {
      navigator.clipboard.writeText('{{ page.password }}');
      const password = document.getElementById('password');
      const originalHTML = password.innerHTML;
      password.innerHTML = '{{ page.password }} <i class="fas fa-check"></i>';
      password.style.color = '#28a745';
      
      setTimeout(() => {
        password.innerHTML = originalHTML;
        password.style.color = '#007bff';
      }, 2000);
    }
    </script>
  CONTENT
  
  File.write(filepath, content)
  puts "Created: #{filename}"
end

def main
  puts "Fetching passwords from Google Sheets..."
  csv_data = fetch_csv_data
  
  puts "Parsing CSV data..."
  passwords = parse_passwords(csv_data)
  
  if passwords.empty?
    puts "No passwords found in the spreadsheet."
    exit 1
  end
  
  puts "\nGenerating #{passwords.size} post(s)..."
  passwords.each do |date, password|
    create_post(date, password)
  end
  
  puts "\nDone! Generated #{passwords.size} WiFi password post(s)."
end

main if __FILE__ == $PROGRAM_NAME