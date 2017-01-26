
Then(/^the length is (.+)$/) do |len|
	if len.nil?
		expect( @cur.length ).to be_nil
	else
		expect( @cur.length ).to eq(len)
	end
end

Then(/^the sequence is (.+)$/) do |seq_name|
	if seq_name.nil?
		expect( @cur.sequence_name ).to be_nil
	else
		expect( @cur.sequence_name.value ).to eq(seq_name)
	end
end

Then(/^the character edit is (.+)$/) do |val|
	if val.nil?
		expect( @cur.character_edit.value ).to be_nil
	else
		expect( @cur.character_edit.value ).to eq(val)
	end
end

Then(/^the column expression is (.+)/) do |str|
	expect( @cur.to_column_expression.gsub(/\s+/, ' ') ).to eq(str)
end




