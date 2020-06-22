require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
       civic_info.representative_info_by_address(
         address: zip,
         levels: 'country',
         roles: %w[legislatorUpperBody legislatorLowerBody]
       ).officials

       legislator_names = legislators.map(&:name)
       legislator_names.join(', ')
     rescue StandardError
       'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
     end
end

def save_thank_you_letter(id, form_letter)
  filename = "output/thanks_#{id}.html"
  Dir.mkdir('output') unless Dir.exist? 'output'

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone)
  reg = /[0-9]/

  phone = phone.chars.delete_if { |char| char.match(/\d/).nil? }.join('')

  if phone.length == 10 || (phone.length == 11 && phone[0] == 1)
    phone = phone.rjust(11, '0')[1..-1]
  else
    'invalid number'
  end
end

all_hours = []
all_days = []

def filter_hours_days(date_time, all_days, all_hours)
  time_format = '%m/%d/%y %H:%M'

  date = DateTime.strptime(date_time, time_format)

  reg_hour = date.hour
  reg_wday = date.wday

  all_days << reg_wday
  all_hours << reg_hour
end

def display_days_hours(all_hours, all_days)
  frequent_hours = all_hours.uniq.sort_by { |h| all_hours.count(h) }.reverse
  frequent_days = all_days.uniq.sort_by { |h| all_days.count(h) }.reverse

  puts 'Hours where the most users registered:'
  puts frequent_hours
  puts '------------'
  puts 'Days when the most users registered:'
  puts frequent_days
end

puts 'Event Manager Initialized!'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = row[:homephone]
  date_time = row[:regdate]
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  phone = clean_phone_numbers(phone)

  filter_hours_days(date_time, all_days, all_hours)
end

display_days_hours(all_hours, all_days)
