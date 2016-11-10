require 'node_extensions.rb'
require 'basic_extensions.rb'

module Narp

  class Fields < Treetop::Runtime::SyntaxNode
    def fields 
      @myelements ||= mysearch(Field)
    end
  end

  class FixedField < Treetop::Runtime::SyntaxNode
  end

  class ByteBitPosition < Treetop::Runtime::SyntaxNode
  end

  class FormatLength < Treetop::Runtime::SyntaxNode
  end

  class DateTimeSeperator < Treetop::Runtime::SyntaxNode
  end

  class DateTimeComponent < Treetop::Runtime::SyntaxNode
    attribute [DateTimeSeperator, :seperator]

    def value
      offset = (seperator && -1*seperator.text_value.length - 1) ||  -1
      text_value.slice(0 .. offset).downcase
    end

    def is_a_type?(part)
      part == date_type 
    end

    def type
      if ['year', 'yy'].detect{|d| d == value}
        :year
      elsif ['mm', 'mm0', 'mmth', 'mon', 'mn'].detect{|d| d == value}
        :month
      elsif ['dd', 'dd0', 'ddth', 'day', 'dy'].detect{|d| d == value}
        :day
      elsif ['hh', 'hh0', 'hr', 'hr0'].detect{|d| d == value}
        :hour
      elsif ['mi', 'mi0'].detect{|d| d == value}
        :minute
      elsif ['se', 'se0'].detect{|d| d == value}
        :second
      elsif ['am', 'a.m.'].detect{|d| d == value}
        :meridiem_indicator
      end
    end

    def date_regex 
      case value
        when 'year'
          '(\d{4})' 
        when 'yy'
          '(\d{2})'
        when 'mm', 'dd', 'hh', 'hr', 'mi', 'se'
          '(\d{1,2})'
        when 'mm0', 'dd0', 'hh0', 'hr0', 'mi0', 'se0'
          '(\d{2})'
        when 'mmth', 'ddth'
          '(\d{1,2})(?:st|nd|rd|th)'
        when 'mon'
          '(january|february|march|april|may|june|july|august|september|october|november|december)'
        when 'mn'
          '(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\.?'
        when 'day'
          '(monday|tuesday|wednesday|thursday|friday|saturday|sunday)'
        when 'dy'
          '(mon|tu|tue|tues|wed|th|thu|thur|thrus|fri|sat|sun)\.?'
        when 'am'
          '(am|pm)'
        when 'a.m.'
          '(a.m.|p.m.)'
      end
    end

    # The actual seperator doesn't matter - just the number of characters
    def regex_pattern
      seperator ? date_regex << ".{#{seperator.text_value.length}}" : date_regex
    end
  end

  class DateTime < Treetop::Runtime::SyntaxNode
    attributes [DateTimeComponent, :components]
  end

  class NumericFormat < Treetop::Runtime::SyntaxNode
  end

  module DateTimeComponentArray
    def index(type)
      index{|o| o.type == type}
    end
  end

  class FieldFormat < Treetop::Runtime::SyntaxNode
    include RegexHql
    attributes [DateTimeComponent, :dt_parts]
    attribute NumericFormat
    attr :regex, :format_string

    def value
      ['character', 'bit'].detect{|d| text_value =~ /#{d}/i } || 
      (myfind(DateTime) && 'datetime') || numeric_format && ['integer', 'float', 'dfloat'].detect{|d| numeric_format.value =~ /#{d}/i} || raise( ArgumentError.new("Unknown format") )
    end

    def to_hql
      return nil unless dt_parts.any?
      
      #Generate a regex pattern from the dt_parts
      @regex = OpenStruct.new(:value => dt_parts.collect{|c| c.regex_pattern}.join, :case_insensitive? => true)

      #Generate the format_string
      dt = [:year, :month, :day].collect{|part| _index(part) ? "\\#{_index(part) + 1}" : '01'}.join('-')
      time_pcs = [:hour, :min, :sec].collect{|part| _index(part) ? "\\#{_index(part) + 1}" : '00'}
      mi_idx = _index(:meridiem_indicator) 
      if mi_idx
        mi_ref = 
        hr = time_pcs.shift << " + CASE WHEN LOWER(\\#{mi_idx}) IN ('a.m.', 'am') THEN 0 ELSE 12 END"
        time_pcs.unshift(hr)
      end
     
      @format_string = OpenStruct.new(:value => "#{dt} #{time_pcs.join(':')}")
      # Now call RegexHql.to_hql
      "CAST(#{super} AS TIMESTAMP)" 
    end

    def _index(type)
      dt_parts.index{|d| d.type == type}
    end

  end

  class DelimitedPosition < Treetop::Runtime::SyntaxNode
		def field_num
			text_value =~ /^\s*(\d+)\s*:/
			$1.to_i
		end

		def offset 
			text_value =~ /^\s*\d+\s*:\s*(\d+)/
			$1 && $1.to_i
		end

  end

  class DelimitedStartStop < Treetop::Runtime::SyntaxNode
		attribute [DelimitedPosition, :pos]

    def column_name
      myapp.column_name(field_num)
    end

    def method_missing(meth, *args, &block)
      if pos.respond_to?( meth )
        pos.send( meth, *args )
      end
    end

	end

  class DelimitedStart < DelimitedStartStop
  end

  class DelimitedStop < DelimitedStartStop
  end

  class DelimitedField < Treetop::Runtime::SyntaxNode
		attribute [DelimitedStart, :start], [DelimitedStop, :stop]

    def intra_field?
       stop.nil? || start.field_num == stop.field_num
    end

    def intra_field_expression
      return nil unless intra_field?
      if stop.nil? || !stop.offset
        "SUBSTR(#{start.column_name}, #{start.offset})"
      else 
        "SUBSTRING(#{start.column_name}, #{start.offset}, #{stop.offset - start.offset + 1})" 
      end
    end

    def inter_field_expression
      if start.field_num < stop.field_num
        "CONCAT(" <<  
        [ "SUBSTR(#{start.column_name}, #{start.offset || 1})",
          (start.field_num+1).upto(stop.field_num-1).collect{|i| "#{myapp.column_name(i)}" },
          "SUBSTRING(#{stop.column_name}, 1, #{stop.offset || "LENGTH(#{stop.column_name})"})" 
        ].reject{|r| r.empty?}.join(', ') << ")"
      else
        "CONCAT(" <<  
        [ 
          "SUBSTRING(#{stop.column_name}, 1, #{stop.offset || "LENGTH(#{stop.column_name})"})",
          (stop.field_num-1).downto(start.field_num+1).collect{|i| "#{myapp.column_name(i)}" },
          "SUBSTR(#{start.column_name}, #{start.offset || 1})"
        ].reject{|r| r.empty?}.join(', ') << ")"
      end
    end

    def expression
      intra_field_expression || inter_field_expression
    end
  end

  class PrecisionScale < Treetop::Runtime::SyntaxNode
		def integer_part 
			text_value =~ %r!^\s*(\d+)(?:\s*/\s*(\d+))?!
			$1 && $1.to_i 
		end

		def fractional_part 
			text_value =~ %r!^\s*(\d+)(?:\s*/\s*(\d+))?!
			$2 && $2.to_i
		end
  end

  class FieldModifier < Treetop::Runtime::SyntaxNode
    attribute PrecisionScale

    def integer_part
      precision_scale && precision_scale.integer_part
    end

    def fractional_part
      precision_scale && precision_scale.fractional_part
    end
  end

  class FieldDescription < Treetop::Runtime::SyntaxNode
    attribute FixedField, DelimitedField, FieldFormat 

		def start
			delimited_field.start
		end

		def stop
			delimited_field.stop
		end

    def start_byte_position
      fixed_field.text_value =~ /(\d+)(?:\s*B\s*(\d+))?/i
      return $1
    end

    def start_bit_position
      fixed_field.text_value =~ /(\d+)(?:\s*B\s*(\d+))?/i
      return $2
    end

    def length
      fl = myfind(FormatLength)
      fl && fl.myfind(OrdinalLiteral) 
    end

    def data_type
      field_format ? field_format : OpenStruct.new(:value => 'character', :dt_parts=>[])
    end

    def to_hql 
      if field_format && field_format.to_hql 
        field_format.to_hql.gsub(myapp.placeholder, delimited_field.expression)
      else
        delimited_field.expression
      end
    end

  end

  class Field < NamedNode
    attribute [FieldDescription, :description], [FieldModifier, :modifier]

    def to_column_expression
      "#{description.to_hql} AS #{name}"
    end

    def method_missing(meth, *args, &block)
      if description.respond_to?( meth )
        description.send( meth, *args )
			elsif modifier.respond_to?( meth )
				modifier.send( meth, *args )
      end
    end
  end

end
