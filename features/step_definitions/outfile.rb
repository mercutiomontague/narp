Then(/^the disposition is (\S+)$/) do |match|
	expect( @cur.disposition.value  ).to eq( match )
end

Then(/^the record number starts at (\d+)$/) do |match|
	expect( @cur.record_numbering.value  ).to eq( match.to_i )
end

Then(/^the line seperator is (.+)$/) do |val|
  expect( @cur.line_seperator ).to eq(val)
end


