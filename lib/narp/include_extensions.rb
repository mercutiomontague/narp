require 'narp/node_extensions.rb'
require 'narp/basic_extensions.rb'

module Narp
  class Include < NamedNode
    def condition
      myapp.conditions.detect{|c| c.name.downcase == name.downcase} || OpenStruct.new(:class_name => 'Narp::Condition', :to_s=> 'all', :name=>'all')
    end
  end

  class IncludesList < PositionalList 
    def applicables(obj)
      raise ArgumentError.new("I was expecting only Infile/Outfile, but I got #{obj.class.to_s}") unless obj.is_a?(File)
      start_pos = obj.position
      end_pos = obj.next_position
      select{|s| s.position > start_pos && (end_pos.nil? || s.position < end_pos) }.collect{|i| i.condition}
    end
  end

end
