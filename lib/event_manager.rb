require 'csv'
require 'sunlight/congress'
require 'erb'
require 'Date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letter(id,personalized_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts personalized_letter
  end  
end

def clean_phone(num)
  num = num.to_s.gsub(/[^\d]/, "")
  if num.length == 10
    num.rjust(11,"1")
  elsif num.length == 11 && num[0] == "1"
    num
  else
    "Bad number :-("
  end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

all_hours = []
all_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  personalized_letter = erb_template.result(binding)

  phone = clean_phone(row[5])

  File.open('phone_numbers.txt', 'a') do |file|
     file.puts "#{name} #{row[3]} - #{phone}"
  end

    day, time = DateTime.strptime(row[1],"%m/%d/%y %k:%M").strftime("%A %k").split(" ")
    all_days << day
    all_hours << time

end

day_tally = Hash.new(0)
hour_tally = Hash.new(0)

all_days.each do |day|
  day_tally[day] += 1
end

all_hours.each do |hour|
  hour_tally[hour] += 1
end

File.open('time_analysis.txt', 'w') do |file|
  file.puts "Registrations by day of the week:"
  file.puts day_tally
  file.puts "Registrations by hour:"
  file.puts hour_tally
end

puts "EventManager Complete! Check phone_numbers.txt and time_analysis.txt for more information!"
