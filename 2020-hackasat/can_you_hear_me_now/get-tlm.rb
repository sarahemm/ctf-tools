#!/usr/bin/ruby

require 'socket'

CHAL_HOST='hearmenow.satellitesabove.me'
CHAL_PORT=5032

def decode_7bit(data)
  binstream = ""
  data.each_byte do |byte|
    binstream += byte.to_s(2).rjust(8, "0")
  end

  buf = ""
  binstream.scan(/.{7}/).each do |bin|
    buf += bin.to_i(2).chr
  end
  
  buf
end

def decode_tlm(ip: nil, port: nil)
  puts "Connecting to telemetry service at #{ip}:#{port}..."
  tlm_sock = TCPSocket.new(ip, port)
  packet_nbr = 0
  while(true) do
    print "Packet #{packet_nbr}"
    buf = tlm_sock.read(6)
    len = buf[5].ord
    print " (#{len} bytes)"
    data = tlm_sock.read(len)
    checksum = tlm_sock.read(1)[0].ord
    print ": "
    data.each_byte do |byte|
      printf "%02X ", byte
    end
    printf "/ %02X", checksum
    print " [#{decode_7bit(data)}]\n\n\n"
    packet_nbr += 1
  end
end

ticket = ARGV[0]

puts "Connecting to challenge server at #{CHAL_HOST}:#{CHAL_PORT}..."
sock = TCPSocket.new(CHAL_HOST, CHAL_PORT)
while(line = sock.gets) do
  if(/Ticket please/.match(line)) then
    # request for our ticket
    sock.puts ticket
  elsif(matches = /Telemetry Service running at (\d+\.\d+\.\d+\.\d+):(\d+)/.match(line)) then
    tlm_ip = matches[1]
    tlm_port = matches[2]
    decode_tlm(ip: tlm_ip, port: tlm_port)
  else
    puts line
  end
end
