#!/usr/bin/ruby

modulation = {
  '00' => '-1.0 -1.0',
  '01' => '-1.0 1.0',
  '10' => '1.0 -1.0',
  '11' => '1.0 1.0'
}

input = ARGV[0]

output = []
input.gsub(' ', '').scan(/.{2}/).each do |chunk|
  output << modulation[chunk]
end

puts output.join(' ')
