#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates `date,password` rows for pasting into the Bloom Guest Wi-Fi sheet.
#
# The sheet is the source of truth for the site, and Claude has no tool that can
# write to it, so the rows have to be handed to a human to paste. This script
# exists so that hand-off is exact rather than hand-typed.
#
#   ruby sheet_rows.rb 2026-08-01 2026-08-31                    # random per day
#   ruby sheet_rows.rb 2026-08-01 2026-08-31 --password 6NHTtwFN # one value for all
#
# Output goes to stdout as bare CSV rows with no header, since it is appended
# below existing rows rather than pasted as a fresh sheet.

require 'date'

# Matches the 8-character mixed-case alphanumeric style already in the sheet
# (e.g. 6NHTtwFN, a5LBB7G9). Ambiguous glyphs are left in deliberately: these get
# read off a screen and scanned as QR codes, not transcribed from paper, and
# excluding characters would shrink the space for no real gain.
ALPHABET = [*'a'..'z', *'A'..'Z', *'0'..'9'].freeze
LENGTH = 8

def random_password
  Array.new(LENGTH) { ALPHABET.sample }.join
end

def parse_args(argv)
  fixed = nil
  positional = []

  until argv.empty?
    arg = argv.shift
    case arg
    when '--password', '-p'
      fixed = argv.shift
      abort 'Error: --password needs a value' if fixed.nil? || fixed.empty?
    when '--help', '-h'
      puts <<~USAGE
        Usage: sheet_rows.rb START_DATE END_DATE [--password VALUE]

          START_DATE, END_DATE  inclusive range, YYYY-MM-DD
          --password, -p VALUE  use VALUE for every day (default: random per day)

        Example:
          ruby sheet_rows.rb 2026-08-01 2026-08-31 --password 6NHTtwFN
      USAGE
      exit 0
    else
      positional << arg
    end
  end

  unless positional.size == 2
    abort "Usage: sheet_rows.rb START_DATE END_DATE [--password VALUE]\nRun with --help for details."
  end

  [positional, fixed]
end

def parse_date(str, label)
  Date.parse(str)
rescue Date::Error
  abort "Error: #{label} '#{str}' is not a valid YYYY-MM-DD date."
end

def main(argv)
  (start_str, end_str), fixed = parse_args(argv)

  start_date = parse_date(start_str, 'START_DATE')
  end_date = parse_date(end_str, 'END_DATE')

  if end_date < start_date
    abort "Error: END_DATE (#{end_date}) is before START_DATE (#{start_date})."
  end

  (start_date..end_date).each do |date|
    puts "#{date.strftime('%Y-%m-%d')},#{fixed || random_password}"
  end
end

main(ARGV) if __FILE__ == $PROGRAM_NAME
