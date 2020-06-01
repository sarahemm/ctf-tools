#!/usr/bin/ruby

require 'time'
require 'orbit'

VISIBLE_ELEV = 6
TIME_START = "2020-04-22T00:00:00Z"
TIME_END   = "2020-04-24T00:00:00Z"
IRAN_SPACEPORT = [35.234722, 53.920833, 900]
FAIRBANKS_AK = [64.977488, -147.510697, 302]

tle = "USA-224\n1 37348U 11002A   20053.50800700  .00010600  00000-0  95354-4 0    09\n2 37348  97.9000 166.7120 0540467 271.5258 235.8003 14.76330431    04
"

sat = Orbit::Satellite.new(tle)
spaceport = Orbit::Site.new(*IRAN_SPACEPORT)
downlink = Orbit::Site.new(*FAIRBANKS_AK)

cur_time = Time.parse(TIME_START)
while(cur_time < Time.parse(TIME_END)) do
  tc = spaceport.view_angle_to_satellite_at_time(sat, cur_time)
  elevation = Orbit::OrbitGlobals.rad_to_deg( tc.elevation )
  puts "At #{cur_time.to_s}, sat is at #{elevation.round(2)}° to the spaceport" unless elevation < VISIBLE_ELEV
  
  tc = downlink.view_angle_to_satellite_at_time(sat, cur_time)
  elevation = Orbit::OrbitGlobals.rad_to_deg( tc.elevation )
  puts "At #{cur_time.to_s}, sat is at #{elevation.round(2)}° to the downlink antenna" unless elevation < VISIBLE_ELEV

  cur_time += 60
end

