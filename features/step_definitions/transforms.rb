require 'yaml'

Transform /^(?:parsed|parsing) by (\S+)$/ do |parser_name|
 	if parser_name == 'Narp'
		parser_name
	else
    "Narp::#{parser_name}" 
	end
end	

Transform /^raise (\S+)$/ do |exception|
	except_class = ''
  puts "exception is #{exception}"
	eval( "except_class = #{exception}" )
	except_class
end

Transform /^\S+$/i do |arg|
	arg =~ /\s*null\s*/i ? nil : arg
end

Transform /^(?:pieces|collations|fields|conditions|outfiles|includes|keys) (.+)$/ do |val|
  if val =~ /^\s*\[\]/
    []
  else
    val.split(/\s*,\s*/)
  end
end


Transform /^(app_spec_.+)$/ do |yml_file_name|
  path = Pathname.new(__FILE__).dirname
  filename =  File.expand_path(File.join(path, '..', 'fixtures', "#{yml_file_name}.fixture"))
  lines = File.open(filename, 'r').readlines.join
  YAML.load(lines)
end
