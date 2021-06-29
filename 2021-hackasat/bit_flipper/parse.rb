#!/usr/bin/ruby

infile = File.open(ARGV[0], 'r')

while(!infile.eof)
  data = infile.read(8)
  check = infile.read(1).unpack('C')[0]
  data_bytes = data.unpack('CCCCCCCC').map {|val| sprintf("%02x", val)}
  puts "Data: #{data} [#{data_bytes.join('')}]"
  puts "Check: #{check.to_s(2).rjust(8, '0')}\n\n"
end
