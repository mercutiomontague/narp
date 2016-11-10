Then(/^I have a (\S+) at the root$/) do |class_name|
  expect( @cur.class.to_s ).to eq( "Narp::#{class_name}" )
end

Then(/^I have a (\S+)$/) do |class_name| 
  expect( @cur.elements.collect{|c| c.class.to_s}.uniq ).to include( "Narp::#{class_name}" )
end

Then(/^the 1st element is a (\S+)$/) do |class_name| 
  expect( @cur.elements.collect{|c| c.class.to_s}.uniq ).to start_with( "Narp::#{class_name}" )
end


Then(/^the original filename is (.+)$/) do |match|
  expect( @cur.name.value  ).to eq( match )
end

Then(/^the filename hash is (.+)$/) do |match|
  expect( @cur.name.to_s  ).to eq( match )
end

Then(/^the alias is (\S+)$/) do |match|
  expect( @cur.nick_name  ).to eq( match )
end

Then(/^the number of columns is (\d+)$/) do |match|
  expect( @cur.number_of_columns.to_s ).to eq( match )
end


Then(/^I have an Alias$/) do
  expect( @cur.nick ).to be_an_instance_of( Narp::Alias )
end

Then(/^I have an organization$/) do
  expect( @cur.organization ).to be_an_instance_of( Narp::Organization )
end

Then(/^the organization is (\S+)$/) do |match|  
	expect( @cur.organization.value  ).to eq( match )
end

Then(/^the compressed is (\S+)$/) do |match|  
	expect( @cur.compressed.value  ).to eq( match )
end

When(/^the record length is (\d+), (\d+)$/) do |min, max|
	expect( @cur.record_length.min.to_s ).to eq( min )
	expect( @cur.record_length.max.to_s ).to eq( max )
end

When(/^the field seperator is (.+)$/) do |arg1|
	val = ''	
	eval( 'val = "' << arg1 << '"' )
	expect( @cur.field_seperator.value ).to eq( val )
end

Then(/^skip to record (\d+)$/) do |val|
	expect( @cur.skip_to.to_s ).to eq( val )
end

Then(/^stop after (\d+) records$/) do |val|
	expect( @cur.stop_after.to_s ).to eq( val )
end

Then(/^the record delimiter is (.+)$/) do |arg1|
	val = ''	
	eval( 'val = "' << arg1 << '"' )
	expect( @cur.stream_record_format.value ).to eq(val)
end

Then(/^the record data is stream$/) do
	expect( @cur.stream_record_format).to_not be_nil
end

