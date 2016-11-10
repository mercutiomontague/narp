Then(/^the included condition is (.+) and is a Condition object$/) do |name|
  expect( @cur.condition.class_name ).to eq( 'Narp::Condition' )
  expect( @cur.condition.name ).to eq( name )
end

