
Then(/^the condition is called (\S+)$/) do |name|
  expect( @cur.name ).to eq(name)
end

Then(/^the sql is (.+)/) do |str|
	expect( @cur.to_sql ).to eq(str)
end



 
