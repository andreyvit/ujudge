#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require 'optparse'
require 'ostruct'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = "Usage: script/drbclient [options]"
  
  opts.on( "-h", "--host HOST", String,
           "IP or name of the server" ) do |opt|
    options.host = opt
  end
  
  opts.on( "-p", "--port PORT", Integer,
           "port number of the server" ) do |opt|
    options.port = opt.to_i
  end

  opts.on_tail("-H", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on_tail("--version", "Show version") do
    puts OptionParser::Version.join('.')
    exit
  end
end.parse!



