require 'narp/node_extensions.rb'
require 'narp/basic_extensions.rb'
require 'narp/derived_field_extensions.rb'

module Narp
  class ReformatField < Treetop::Runtime::SyntaxNode

    def side
      text_value.strip.downcase =~ /^(leftside|^rightside)/
      $1
    end

    def value
      text_value.strip =~ /^(?:leftside:|rightside:)?(.+)/i
      $1
    end
  end

  class Reformat < Treetop::Runtime::SyntaxNode
    attributes [ReformatField, :refields]
		
		def _field_names_for_side( side = 'leftside' ) 
      current_side = side if side == 'leftside'
      refields.select{|c|
        current_side = c.side || current_side
        c.side == side || (c.side.nil? && current_side == side)  
      }
		end

		def lhs_names
      _field_names_for_side
		end

		def rhs_names
      _field_names_for_side('rightside')
		end

    def lhs_fields
      myapp.all_fields.select{|f| lhs_names.detect{|d| d.value == f.name}}
    end

    def rhs_fields
      myapp.all_fields.select{|f| rhs_names.detect{|d| d.value == f.name}}
    end

  end

  class OutputSpec < PositionalList
    def lhs_fields(obj = MockObject.new(Infile, :position => 0))
      _applicables(obj).collect{|c| c.lhs_fields}.flatten.compact.uniq
    end
  
    def rhs_fields(obj = MockObject.new(Infile, :position => 0))
      _applicables(obj).collect{|c| c.rhs_fields}.flatten.compact.uniq
    end

    def fields(outfile)
      _applicables(outfile).collect{|c| [c.lhs_fields, c.rhs_fields] }.flatten.compact.uniq
    end
  
    def _applicables(obj)
      return self if first.position < myapp.outfiles.first.position

      start_pos = obj.position
      end_pos = obj.next_position 
      select{|s| s.position > start_pos && (end_pos.nil? || s.position < end_pos) }
    end

    def column_names_for(outfile)
      [any? && fields(outfile) || myapp.all_fields].flatten.compact.collect{|c| 
        side(c) ? "#{side(c)}_#{c.name}" : c.name 
      }
    end

    def src_column_expressions 
      myapp.all_fields.collect{|f|
        side(f) ? "#{side(f)}.#{f.name} AS #{side(f)}_#{f.name}" : f.to_column_expression
      }
    end

    # Returns lhs for tables/fields/derived fields that are required for left side joins/projections
    # Returns rhs for tables/fields/derived fields that are required for right side joins/projections
    # When the app does not call for a join, all tables/fields are considered lhs
    def side(obj)
      return nil if obj.is_a?(DerivedField)
      if any? && rhs_fields.detect{|c| obj.name == c.name} || myapp.joinkeys.rhs_keys.detect{|d| d.name == obj.name}
        :rhs
      else
        :lhs
      end
    end

  end


end
