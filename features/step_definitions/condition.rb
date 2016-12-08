
Then(/^the condition is called (\S+)$/) do |name|
  expect( @cur.name ).to eq(name)
end

Then(/^the hql is (.+)/) do |str|
	# expect( @cur.to_hql.gsub(/\s+/, ' ') ).to eq(str)
  # puts "tree: #{@cur.inspect}"
	expect( @cur.to_hql ).to eq(str)
end



 
