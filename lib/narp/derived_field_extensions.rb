require 'narp/node_extensions.rb'
require 'narp/basic_extensions.rb'

module Narp

  class FormatEdit < Treetop::Runtime::SyntaxNode
  end

  class FormatString < Treetop::Runtime::SyntaxNode
    def value
      text_value.strip.gsub(/^'|'$/, '')
    end

    def fmt_value
      value.gsub(/\\(\d+)/, '%s')
    end

    def group_refs
      value.scan(/(\\\d+)/).flatten
    end
  end

  # This is forward declaration to allow the following two class declarations to compile
  class SourceValue < Treetop::Runtime::SyntaxNode
  end

  class ThenExpression < Treetop::Runtime::SyntaxNode
    attribute SourceValue
  end

  class ElseExpression < Treetop::Runtime::SyntaxNode
    attribute SourceValue
  end

  class ConditionalExpression < Treetop::Runtime::SyntaxNode
    attribute ThenExpression, ElseExpression, [ConditionName, :my_condition_name]

    def then_clause
      then_expression && then_expression.source_value
    end

    def else_clause
      else_expression && else_expression.source_value
    end

    def to_sql(indent=0)
      ["CASE", ["WHEN #{my_condition_name.to_sql} THEN", then_clause.to_sql(indent+1), "ELSE", else_clause.to_sql(indent+1)].join("\n").myindent(1), "END"].join("\n").myindent(indent)
    end

  end

  class NumericFormat < Treetop::Runtime::SyntaxNode
    def to_sql(indent=0)
      case value
      when 'uninteger', 'integer'
        'INTEGER'
      when 'float'
        'FLOAT'
      when 'dfloat'
        'DOUBLE'
      end
    end
  end

  class RegexType < Treetop::Runtime::SyntaxNode
    include RegexHql
    attribute Regex, FormatString

    def length
      nil
    end
  end

  module CommonTypeBehavior
    def to_sql(indent=0)
      regex_type.to_sql(indent)
    end

    def length 
      integer_literal && integer_literal.value
    end
  end

  class NumericType < Treetop::Runtime::SyntaxNode
    include CommonTypeBehavior
    attribute NumericFormat, FormatEdit, PrecisionScale 
    attribute RegexType, IntegerLiteral

    def integer_part
      precision_scale && precision_scale.integer_part
    end

    def fractional_part
      precision_scale && precision_scale.fractional_part
    end
  end

  class CharacterType < Treetop::Runtime::SyntaxNode
    include CommonTypeBehavior
    attribute RegexType, IntegerLiteral
  
  end

  class DerivedType < Treetop::Runtime::SyntaxNode
    attribute CharacterType, FormatEdit, SequenceName
    attribute NumericType, RegexType

		def to_sql(indent)
      candidate.to_sql(indent) if candidate 
		end

		def length
			candidate.length if candidate 
		end

		def candidate
			[character_type, numeric_type, regex_type].compact.first
		end

		def regex
			candidate && (candidate.is_a?(RegexType) ? candidate : candidate.regex_type)
		end

    def integer_part
      numeric_type && numeric_type.integer_part
    end

    def fractional_part
      numeric_type && numeric_type.fractional_part
    end

		def right_trim?
			format_edit && format_edit.value == 'truncate'
		end

		def trim?
			format_edit && format_edit.value == 'compress'
		end

		def data_type
			case
				when character_type	
					'VARCHAR'
				else
					'Unknown'
			end
		end

  end

  class SourceValue < Treetop::Runtime::SyntaxNode
    # attribute FieldName, NumericValue, ConditionalExpression, String
    attribute ConditionalExpression, Expression, NumericTerminal, CharacterTerminal, String

    def to_sql(indent=0)
      if myobj.is_a?(ConditionalExpression)
        myobj.to_sql(indent)
      else
        myobj.to_sql.myindent(indent)
      end
    end

    def myobj
      # conditional_expression || field_name ||  numeric_value || string
      conditional_expression || expression || numeric_terminal || character_terminal || string
    end

    def fields
      n = mysearch(FieldName).uniq
      myapp.fields.select{|s| s.name == n.value}
    end
  end

  class DerivedFieldExpression < Treetop::Runtime::SyntaxNode
    attribute SourceValue, DerivedType

    def to_sql(indent=0)
			return source_value.to_sql(indent) unless derived_type

      z = if derived_type.regex
        derived_type.to_sql(indent).gsub(myapp.placeholder, source_value.to_sql)
      else
        source_value.to_sql(indent)
      end

			# Format to precision or trim the result if necessary
      (format_to_precision(z) || format_to_length(z)).myindent(indent)
		end			

    def format_to_precision(z)
      return nil unless integer_part
      "printf('%#{[integer_part, fractional_part].compact.join('.')}f', #{z})"
    end

    def format_to_length(z)
			# Cast to the data type
			z = "CAST(#{z} AS VARCHAR(#{length}))" if length
      if derived_type.right_trim?
			  "RTRIM(#{z})" 
			elsif derived_type.trim?
				"TRIM(#{z})"
			else
				z
      end
    end

		def sequence_name
			derived_type && derived_type.sequence_name
		end

    def fields
      source_value.fields
    end

    def method_missing(meth, *args, &block)
      if derived_type && derived_type.respond_to?( meth )
        derived_type.send( meth, *args )
      end
    end
  end

  class BuiltinField < Treetop::Runtime::SyntaxNode
  end

  class DerivedField < NamedNode
    attribute BuiltinField, DerivedFieldExpression 

    def to_column_expression(indent=0)
      to_sql(indent) << " AS #{name}"
    end

    def to_sql(indent=0)
      (builtin_field ||  derived_field_expression).to_sql(indent) 
    end

    def method_missing(meth, *args, &block)
      if builtin_field && builtin_field.respond_to?( meth )
        builtin_field.send( meth, *args )
			elsif derived_field_expression.respond_to?( meth )
				derived_field_expression.send( meth, *args )
      end
    end
  end

end
