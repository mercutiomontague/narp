Given(/^an input (.+)$/) do |input|
  # Because of the way Gherkin processes examples, \1, \2 etc are ignored.  
  # To work around this, I provide #1, #2 etc.  We therefore need to convert these to simply
  # \1, \2 etc before passing it to the parser to process
  input.gsub!(/#(\d)/) {|match| "\\#{$1}"}
	@input = input
end

When(/^(parsed by \S+)\s*(.+)?$/) do |parser_name, flags|
  myapp.init if flags =~ /--i/i
  @tree = Narp::SyntaxTree.new(parser_name).parse(@input)
  @cur = @tree
  puts @tree.inspect if flags =~ /--v/i 
end

Then(/^(parsing by \S+) should (raise \S+)$/) do |parser, exception|
  expect{ Narp::SyntaxTree.new(parser).parse(@input) }.to raise_error( exception )
end

Then(/^the value is (.+)$/) do |arg1|
  # Because of the way Gherkin processes examples, \1, \2 etc are ignored.  
  # To work around this, I provide #1, #2 etc.  We therefore need to convert these to simply
  # \1, \2 etc before passing it to the parser to process
  arg1.gsub!(/#(\d)/) {|match| "\\#{$1}"}
  expect( @cur.value ).to eq(arg1)
end

Then(/^the regexp should match (.+)$/) do |match|
	expect( @cur.match(match) ).to be_a(MatchData)
end
    
