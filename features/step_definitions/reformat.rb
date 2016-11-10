Then(/^we have the left (fields .+)$/) do |list|
  expect( @cur.lhs_names.collect{|c| c.value} ).to contain_exactly( *list )
end

Then(/^we have the right (fields .+)$/) do |list|
  expect( @cur.rhs_names.collect{|c| c.value} ).to contain_exactly( *list )
end


