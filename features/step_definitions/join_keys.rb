
Then(/^these (keys .+)$/) do |list|
	expect( @cur.keys.collect{|k| k.name}.sort ).to contain_exactly( *(list.sort) )
end

Then(/^the sort attribute is (\S+)$/) do |val|
	if val.nil?
		expect( @cur.sorted ).to be_nil
	else
		expect( @cur.sorted ).to eql(val)
	end
end

Then(/^the keys are Field objects$/) do
 	expect( @cur.keys.collect{|c| c.class_name}.uniq ).to contain_exactly( 'Narp::Field' ) 
end


