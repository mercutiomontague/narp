When(/^I am examining the (\d+)(?:st|nd|rd|th) field$/) do |num|
  @cur = @tree.fields[num.to_i - 1]    
end

Then(/^I have (\d+) Field$/) do |num|
  expect( @tree.fields.size ).to eq( num.to_i )
end

Then(/^the name is (.+)$/) do |name|
 expect( @cur.name ).to  eq( name )
end

Then (/^the starting byte position is (\d+) and offset is (\S+) bits$/) do |pos, offset|
	expect( @cur.start_byte_position ).to eq( pos )
	expect( @cur.start_bit_position ).to eq( offset )
end

Then(/^the datatype is (.+)$/) do |val|
 	expect( @cur.data_type.value ).to match( val.strip )
end

Then(/^it is (\S+) bytes long$/) do |val|
	expect( @cur.length && @cur.length.value ).to eq( val )
end

Then(/^it has these datetime (pieces .+)$/) do |list|
  ar = @cur.data_type.dt_parts.collect{|a| a.value}
 	expect( ar ).to eq( list )
end

Then(/^there are (\d+) fields$/) do |num|
 	expect( @tree.fields.size ).to eq( num )
end


Then(/^the start field is (\S+) with byte offset of (\S+)$/) do |num, offset|
  if num.nil?
    expect( @cur.start.field_num ).to eq(num)
  else
    expect( @cur.start.field_num.to_s ).to eq(num)
  end
  if offset.nil?
    expect( @cur.start.offset	 ).to eq(offset)
  else
    expect( @cur.start.offset.to_s ).to eq(offset)
  end
end

Then(/^the stop field is (\S+) with byte offset of (\S+)$/) do |num, offset|
	if num.nil?
		expect( @cur.stop ).to eq(nil)
	else	
  	expect( @cur.stop.field_num.to_s ).to eq(num)
    if @cur.stop.offset
  	  expect( @cur.stop.offset.to_s	 ).to eq(offset)
    else
  	  expect( @cur.stop.offset ).to eq(offset)
    end
	end
end

Then(/^the precision is (\d+) and the scale is (\d+)$/) do |precision, scale|
	expect( @cur.integer_part  ).to eq(precision.to_i - scale.to_i)
	expect( @cur.fractional_part ).to eq(scale.to_i)
end

Then(/^the collation is (\S+)$/) do |sequence_name|
	expect( @cur.sequence.value ).to eq( sequence_name )
end

Then(/^the datatype should raise ArgumentError$/) do
  expect{ @cur.data_type.value }.to raise_error(ArgumentError)
end



