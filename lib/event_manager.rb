require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "time"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone(phone)
  phone = phone.to_s.gsub(/\D/, '')
  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == '1'
    phone[1..10]
  else
    "Invalid phone number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


puts "EventManager initialized."

contents = CSV.open(
  "./data/event_attendees_small.csv",
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.html.erb")
erb_template = ERB.new template_letter

avg_time,rows = 0, 0
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone = clean_phone(row[:homephone])
  time = row[:regdate]
  date_time = Time.strptime(time, "%m/%d/%y %k:%M")
  # Average the unix times
  avg_time += date_time.strftime("%s").to_i


  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  form_letter.include?(name) # No-op to use the variable
  form_letter.include?(zipcode) # No-op to use the variable
  form_letter.include?(phone) # No-op to use the variable
  form_letter.include?(legislators) # No-op to use the variable

  save_thank_you_letter(id, form_letter)
  rows = rows + 1
end


puts "Average time is #{Time.at(avg_time / rows).strftime("%m/%d/%y %k:%M")}"
