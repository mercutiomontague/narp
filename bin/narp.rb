#!/usr/bin/env ruby
#
require 'narp.rb'

def parse_options
  options = OpenStruct.new
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: narp.rb [options] narp_program_definition"
    mess =  "\nIf the program definition is provided on the command line: \n"
		mess += "1) it must be enclosed in double quotes.\n"
		mess += "2) double quotes and $ within the program definition must be escaped.\n\n"
		mess += "Option:\n"

		opts.separator mess

    opts.on('--domain NAMESPACE', 'Specify the namespace to group this program within') do |n|
      options.domain = n
    end

    opts.on('--file PROGRAM_FILE', 'Read the Narp program definition from PROGRAM_FILE') do |q|
      options.program_file = q
    end

  end
  opt_parser.parse!(ARGV)
  options
end

def read_program_file(opt)
  return nil unless opt.program_file
  File.open(opt.program_file, 'r').readlines.join("\n")
end

opts = parse_options
myapp.init(opts.domain)
program = read_program_file(opts) || ARGV.join(' ')
myapp.parse(program)
puts myapp.generate_json_output
