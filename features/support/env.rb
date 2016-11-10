require 'rspec/expectations'
require 'treetop'
require 'narp/node_extensions.rb'
require 'narp/syntax_tree.rb'
require 'narp_app.rb'
require 'diffy'



def assert_matching_string(lhs, rhs)
  d = Diffy::Diff.new(lhs.strip, rhs.strip, :context=>2)
  return 1 if d.to_s.empty?
  raise RSpec::Expectations::ExpectationNotMetError.new( d.to_s ) 
end
