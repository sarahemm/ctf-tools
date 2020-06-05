#!/usr/bin/ruby

require 'socket'
require 'yaml'
require 'colorize'

WHL_WARN = 6800

#- sun_point: Charges the batteries by pointing the panels at the sun.
#- imaging: Trains the imager on the target location and begins capturing image data.
#- data_downlink: Slews the spacecraft to point it's high bandwidth downlink transmitter at the ground station and transmits data to the station.
#- wheel_desaturate: Desaturates the spacecraft reaction wheels using the on board magnetorquers.

mission = [
  ['2020-04-22T00:00:00Z', :sun_point], # charge batteries while transiting

  ['2020-04-22T09:28:00Z', :imaging],   # image the spaceport
  ['2020-04-22T09:35:00Z', :sun_point], # no longer in view, charge again
  ['2020-04-22T10:47:00Z', :data_downlink], # AOS at Fairbanks, downlink
  ['2020-04-22T10:51:00Z', :sun_point], # LOS, charge again
  
#  ['2020-04-22T20:25:00Z', :imaging],   # image the spaceport
#  ['2020-04-22T20:29:00Z', :sun_point], # no longer in view, charge again
#  ['2020-04-22T22:22:00Z', :data_downlink], # AOS at Fairbanks, downlink
#  ['2020-04-22T22:26:00Z', :sun_point], # LOS, charge again
  
  ['2020-04-23T08:45:00Z', :wheel_desaturate], # desat wheels using magnetorqer
  
  ['2020-04-23T09:51:00Z', :imaging],   # image the spaceport
  ['2020-04-23T09:57:00Z', :sun_point], # no longer in view, charge again
  ['2020-04-23T11:10:00Z', :data_downlink], # AOS at Fairbanks, downlink
  ['2020-04-23T11:13:00Z', :sun_point], # LOS, charge again

  ['2020-04-23T20:00:00Z', :wheel_desaturate], # desat wheels using magnetorqer
]

def process_tlm(curtime, tlmstr)
  tlm = YAML.load(tlmstr)
  adcs = tlm['adcs']
  mag_pwr_x = adcs['mag_pwr'][0] ? "ON" : "OFF"
  mag_pwr_y = adcs['mag_pwr'][1] ? "ON" : "OFF"
  mag_pwr_z = adcs['mag_pwr'][2] ? "ON" : "OFF"

  whl_rpm_x = adcs['whl_rpm'][0]
  whl_rpm_y = adcs['whl_rpm'][1]
  whl_rpm_z = adcs['whl_rpm'][2]
  
  warnings = []

  if(whl_rpm_x > WHL_WARN or whl_rpm_y > WHL_WARN or whl_rpm_z > WHL_WARN) then
    warnings.push "One or more wheels is approaching saturation!"
  end

  puts "TIME: #{curtime}"
  puts "BATT: #{tlm['batt']['percent'].round}%\t#{tlm['batt']['temp'].round(2)}C"
  puts "OBC:  Disk #{tlm['obc']['disk'].round}%\t\t\t#{tlm['obc']['temp'].round(2)}C"
  puts "COMM: #{tlm['comms']['pwr'] ? 'ON' : 'OFF'}\t\t\t#{tlm['comms']['temp'].round(2)}C"
  puts "CAM:  #{tlm['cam']['pwr'] ? 'ON' : 'OFF'}\t\t\t#{tlm['cam']['temp'].round(2)}C"
  puts "MGTQ: X #{mag_pwr_x}   Y #{mag_pwr_y}   Z #{mag_pwr_z}"
  puts "RWHL: X #{whl_rpm_x.round}  Y #{whl_rpm_y.round}  Z #{whl_rpm_z.round}"
  puts "ADCS: Mode '#{adcs['mode']}'\t\t#{adcs['temp'].round(2)}C"
  puts "SOLR: #{tlm['panels']['illuminated'] ? 'Illuminated' : 'Dark'}"
  puts "\n#{warnings.join(", ").yellow}\n" if warnings
  puts "\n---\n"
end

ticket = ARGV[0]

sock = TCPSocket.new('mission.satellitesabove.me', 5023)
while(line = sock.gets) do
  if(/Ticket please/.match(line)) then
    # request for our ticket
    sock.puts ticket
  elsif(/Please input mission/.match(line)) then
    # request to enter mission steps, do that then run the mission
    mission.each do |step|
      sock.puts "#{step[0]} #{step[1].to_s}"
    end
    sleep 1
    sock.puts 'run'
  elsif(/^Collected Data: \d+ bytes/.match(line)) then
    # data collection report
  elsif(/^2020/.match(line)) then
    # time update
    cur_time = line
  elsif(line[0] == '{') then
    # telemetry report
    process_tlm cur_time, line 
  else
    puts line
  end
end
