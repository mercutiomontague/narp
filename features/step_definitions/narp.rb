require 'open3'

def narp_executable
	File.expand_path(File.join( Pathname.new(__FILE__).dirname, '..', '..', 'bin', 'narp.rb'))
end

Given(/^that Narp is invoked with program_definition from (app_spec_\S+)$/) do |yml|
  input = yml['program_definition'].gsub('"', '\"').gsub("\n", ' ')
	cmd = %Q[ #{narp_executable} "#{input}" ]
  puts "About to execute: #{cmd}"

	Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
		@stdout = stdout.read	
		@stderr = stderr.read
		raise ArgumentError.new( @stderr ) if wait_thr.value.exitstatus > 0
	end
end

Then(/^the (.+) should match (app_spec_\S+)$/) do |type, yml|
  if type == 'stdout'
    actual = JSON.parse(@stdout)
    yml.reject!{|k, v| k == 'program_definition'}
		expect( yml.keys.sort ).to eql( actual.keys.sort )
		yml.keys.each {|k|
			assert_matching_string( actual[k].to_s, yml[k].to_s ) 
		}
  else
	  assert_matching_string( myapp.send(type), yml[type] )
  end
	# puts myapp.send(type)
end

Then(/^show stdout$/) do
  puts @stdout
end

