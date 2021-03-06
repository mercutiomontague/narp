module DummyToHql
  def to_sql(indent=0)
    "_#{name}_"
  end
end

Given(/^the app has (collations .+)$/) do |list|
  myapp.collations = list.collect{|o| OpenStruct.new(:name => o, :class_name=>'Narp::Collation').extend(DummyToHql)}
end

Given(/^the app has (outfiles .+)$/) do |list|
  myapp.outfiles = list.collect{|o| OpenStruct.new(:name => o, :class_name=>'Narp::Outfile').extend(DummyToHql)}
end

Given(/^the app has (includes .+)$/) do |list|
  myapp.includes = list.collect{|o| OpenStruct.new(:name => o, :class_name=>'Narp::Include').extend(DummyToHql)}
end

Given(/^the app has (conditions .+)$/) do |list|
  myapp.conditions = list.collect{|o| OpenStruct.new(:name => o, :class_name=>'Narp::Condition').extend(DummyToHql)}
end

Given(/^the app has (numeric|character) (fields .+)$/) do |type, list|
  if type == 'numeric'
    list.each {|o| myapp.fields << OpenStruct.new(:name => o, :data_type => OpenStruct.new(:value => 'integer'), :class_name => 'Narp::Field').extend(DummyToHql)}
  else
    list.each {|o| myapp.fields << OpenStruct.new(:name => o, :data_type => OpenStruct.new(:value => 'character'), :class_name => 'Narp::Field').extend(DummyToHql)}
  end
end


Given(/^the app parses (.+)$/) do |input|
  myapp.parse(input)
end


Given(/^I am examining my app's (\d+)(?:st|nd|rd|th) (\S+)$/) do |num, object|
  @tree = myapp.send( "#{object}s" )
  @cur = @tree[num.to_i - 1]
end

Given(/^additional (outfiles .+)$/) do |list|
  myapp.outfiles << list.collect{|o| OpenStruct.new(:name => o)}
end

Given(/^an existing app that is reinitialized( with (.+) domain)?$/) do |phrase, domain|
  myapp.init(domain: domain)
end

Given(/^an existing (.+) app that is reinitialized( with (.+) domain)?$/) do |sys, phrase, domain|
  myapp.init(domain: domain, sys: sys)
end

Given(/^additional (includes .+)$/) do |list|
  myapp.includes << list.collect{|o| OpenStruct.new(:name => o)}
end

Given(/^the app has derived (fields .+)$/) do |list|
  list.each {|o| 
    myapp.derived_fields << OpenStruct.new(:name => o).extend(DummyToHql)
  }
end

Then(/^I expect outfiles with these (pieces .+)$/) do |list|
  exp_list = myapp.outfiles.collect{|c| "#{c.name}:#{c.position.to_i}" }.flatten.sort_by{|a, b| a <=> b}
  expect( exp_list ).to eq( list )
end

Then(/^I expect includes with these (pieces .+)$/) do |list|
  exp_list = myapp.includes.collect{|c| "#{c.name}:#{c.position.to_i}" }.flatten.sort_by{|a, b| a <=> b}
  expect( exp_list ).to eq( list )
end

Then(/^the position is (\d+)$/) do |num|
  expect(@cur.position).to eq(num.to_i)
end

Then(/^the app join clauses are (.+)$/) do |clauses|
	expect( myapp.join_clause.gsub(/\s+/, ' ').squeeze(' ').downcase ).to eq( clauses.gsub("$schema", myapp.schema) )
end

Then(/^show the app (.+)$/) do |type|
  if type == 'infile s3 mappings'
    puts myapp.infiles.s3_mappings 
  elsif type == 'outfile s3 mappings'
    puts myapp.outfiles.s3_mappings 
  else
    puts myapp.send(type)
  end
end

Then(/^my app has (.+) jointype$/) do |side|
	expect( myapp.join_type ).to eq(side) 
end

Then(/^the base_sequence is (.+)$/) do |val|
  expect( @cur.base_sequence ).to eq(val)  
end

Then(/^the normalized text is (.+)$/) do |txt|
  expect( @cur.to_normalized ).to eql( txt ) 
end


Then(/^the app normalized text is (.+)$/) do |txt|
  expect( myapp.normalized_nql.to_s ).to eql( txt ) 
end

Then (/^app's (.+) is set to (.+)$/) do |meth, val|
  m = "#{meth}="
  puts "---> m is #{m}, #{myapp.s3_in_bucket_uri}"
  myapp.s3_in_bucket_uri = val
  puts "+++> #{myapp.s3_in_bucket_url}"
  myapp.send("#{m}", val)
end


Then (/^the app's (.+) is (.+)$/) do |meth, val|
  expect( myapp.send(meth) ).to eql(val)
end
