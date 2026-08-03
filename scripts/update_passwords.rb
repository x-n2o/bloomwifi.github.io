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
# The password value is always quoted in front matter so that all-digit
# passwords stay strings (unquoted YAML would coerce them to integers).
FRONT_MATTER_PASSWORD_PATTERN = /^password:\s*.*$/
# Matches the QR tag line in both the canonical form (P:{{ page.password }})
# and the legacy form that inlined the literal password.
QR_TAG_PATTERN = /\{% qr WIFI:T:WPA;S:Bloom Guest;P:[^;]+; %\}/
# The canonical QR line: the password is referenced via Liquid (expanded by
# the jekyll-qr fork pinned in the Gemfile), never inlined as a literal.
QR_LINE = '{% qr WIFI:T:WPA;S:Bloom Guest;P:{{ page.password }}; %}'

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

  CSV.parse(csv_data, headers: true).each_with_index do |row, idx|
    date_str = row['date'] || row[0]
    password = (row['password'] || row[1]).to_s.strip

    next if date_str.to_s.strip.empty? || password.empty?
    
    begin
      date = Date.parse(date_str)
      passwords[date] = password
    rescue Date::Error => e
      puts "Warning: Invalid date format '#{date_str}' on row #{idx + 2}: #{e.message}"
    end
  end
  
  passwords
end

def posts_dir
  File.join(__dir__, '..', '_posts')
end

def post_path(date)
  File.join(posts_dir, "#{date.strftime('%Y-%m-%d')}-wifi.md")
end

def local_post_dates
  return [] unless Dir.exist?(posts_dir)
  
  Dir.glob(File.join(posts_dir, '*-wifi.md')).map do |filepath|
    filename = File.basename(filepath)
    date_str = filename.match(/^(\d{4}-\d{2}-\d{2})-wifi\.md$/)&.[](1)
    Date.parse(date_str) if date_str
  end.compact
end

def create_post(date, password)
  FileUtils.mkdir_p(posts_dir)
  
  filename = "#{date.strftime('%Y-%m-%d')}-wifi.md"
  filepath = post_path(date)
  
  content = <<~CONTENT
    ---
    layout: post
    password: "#{password}"
    ---
    <h3>{{ page.date | date: "%A, %B %e, %Y" }}</h3>
    <h1 id="password" onclick="copyToClipboard()" style="cursor: pointer; color: #007bff;">{{ page.password }} <i class="fas fa-copy"></i></h1>
    #{QR_LINE}

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

def update_post(date, password)
  filepath = post_path(date)
  filename = File.basename(filepath)

  unless File.exist?(filepath)
    create_post(date, password)
    return :created
  end

  content = File.read(filepath)
  front_matter_line = content[FRONT_MATTER_PASSWORD_PATTERN]
  qr_line = content[QR_TAG_PATTERN]

  return :unchanged if front_matter_line == "password: \"#{password}\"" && qr_line == QR_LINE

  unless front_matter_line && qr_line
    warn "Error: #{filename} is missing the expected password fields."
    exit 1
  end

  # Also migrates legacy posts (unquoted front matter or a literal password
  # inlined in the QR tag) to the canonical form; the replacement is a
  # constant, so a literal can never be reintroduced.
  updated = content
            .sub(FRONT_MATTER_PASSWORD_PATTERN, "password: \"#{password}\"")
            .sub(QR_TAG_PATTERN, QR_LINE)
  File.write(filepath, updated)
  puts "Updated: #{filename}"
  :updated
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
  
  counts = Hash.new(0)
  passwords.sort.each do |date, password|
    counts[update_post(date, password)] += 1
  end
  
  extra_dates = local_post_dates - passwords.keys
  if extra_dates.any?
    filenames = extra_dates.sort.map { |date| "#{date.strftime('%Y-%m-%d')}-wifi.md" }
    puts "Warning: #{extra_dates.size} local post(s) not found in the spreadsheet: #{filenames.join(', ')}"
  end
  
  puts "\nDone! #{passwords.size} spreadsheet rows checked; " \
       "#{counts[:created]} created, #{counts[:updated]} updated, " \
       "#{counts[:unchanged]} unchanged."
end

main if __FILE__ == $PROGRAM_NAME
