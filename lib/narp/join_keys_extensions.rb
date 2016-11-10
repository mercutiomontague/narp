require 'node_extensions.rb'
require 'basic_extensions.rb'

module Narp
  class JoinKeys < Treetop::Runtime::SyntaxNode
    attributes FieldName
		
		def sorted
			text_value.strip.downcase	=~ /(sorted)/
			$1
		end

		def keys
			myapp.fields.select{|s| field_names.detect{|d| d.value == s.name }}
		end

    def fields(ignore=nil)
      keys
    end
  end

  class JoinKeysList < PositionalList
    def <<(*others)
      super
      raise ArgumentError.new("I'm not sure how to interpret an application with more than 2 joinkeys clauses, since lhs/rhs tables becomes ambiguous.") if size > 2
    end
  
    def lhs_keys
      any? && first.keys || []
    end
  
    def rhs_keys
      any? && last.keys || []
    end
  
    def first_position
      first.position
    end

    def predicate_hql
      return nil unless any?
      DualIterator.new(lhs_keys, rhs_keys).collect{|e| "lhs.#{e.first.name} = rhs.#{e.last.name}"}.join("\n\tAND ").prepend("\tON ") 
    end
  end

end
