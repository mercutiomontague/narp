require 'narp/parse_issue.rb'
require 'ostruct'

module Narp 
  class MyIdentifier < Treetop::Runtime::SyntaxNode
	  def value
	  	z = text_value.gsub(/\s/, '')
	  end
  end

  class TerminalNode < Treetop::Runtime::SyntaxNode
    def to_s
      value
    end

    def to_hql(indent=0)
      to_s
    end
  end

  class NamedNode < Treetop::Runtime::SyntaxNode
    attribute [MyIdentifier, :myid]
  
    def name
      myid.value
    end

    def to_hql(indent=0)
      name
    end
  end

  class Domain < NamedNode
  end
  
  class NodeReference < NamedNode
    def to_hql(indent=0)
      myapp.get(name, self.class).to_hql(indent) 
    end
  end

  class FieldName < NamedNode
    def to_hql(indent=0)
      "#{myapp.output_spec.side(self)}_#{name}"
    end
  end

  class NumericFieldName < FieldName
  end

  class CharacterFieldName < FieldName
  end

  class ConditionName < NodeReference
  end

  class DerivedFieldName < NodeReference
    def to_hql(indent=0)
      '(' << super << ')'
    end
  end

  class SequenceName < Treetop::Runtime::SyntaxNode
  end

  class OrdinalLiteral < TerminalNode
  end
  
  class IntegerLiteral < TerminalNode
  end

  class FloatLiteral < TerminalNode
  end
  
  class DoubleFloatLiteral < TerminalNode
  end
  
  class EditedNumeric < TerminalNode
    def value
      super.gsub(',', '')
    end
  end

  class ParenthesisLiteral < TerminalNode
  end

  class IntegerNode < Treetop::Runtime::SyntaxNode
    attribute [IntegerLiteral, :int]

    def value
      int.value
    end

    def to_s
      value
    end
  end
  
  module StringAbilities 

    @@escapes = {'\t' => "\t", '\v' => "\v", '\b' => "\b", '\n' => "\n", '\r' => "\r", '\f' => "\f", '\'' => "'", '\\' => "\\" }

    def value
      # Throw an exception if we encounter an octal, since we don't deal with that yet.
      raise ArgumentError.new("I haven't implemented a way to translate octal delimieters yet.") if is_oct?
    
      # Convert all escaped characters
      @@escapes.keys.inject(escaped_value) {|memo, k| memo.gsub(k, @@escapes[k]) } 
    end

    def escaped_value
      result = inner_value * multiplier
      # Convert all hex to their equivalent decimal characters
      result = result.gsub(/\\x([0-9A-F]{2})/i) {|match|  hex_digits = match[2..-1]; [hex_digits].pack("H*") }
      is_hex_string? ? [result].pack("H*") : result 
    end

    def to_s
      value
    end

    def to_hql(indent=0)
      "'#{value}'"
    end

    def is_escaped?
      inner_value =~ /^\\/  
    end

    def multiplier
      text_value.strip.gsub(inner_value, '') =~ /^(\d+)/
      $1 && $1.to_i || 1
    end

    def is_hex_string?
      text_value.strip =~ /^(\d+\s*)*X/i
    end

    def is_oct?
      text_value.strip =~ /^(\d+\s*)*O/i
    end

    def inner_value
      text_value.strip =~ /"(.+)"|'(.+)'/
      $1 || $2
    end
  end

  class String < Treetop::Runtime::SyntaxNode
    include StringAbilities
  end

  class SingleQuotedString < TerminalNode
    include StringAbilities
  end

  class DoubleQuotedString < TerminalNode
    include StringAbilities
  end


  class Regex < Treetop::Runtime::SyntaxNode
    def value
      text_value.strip =~ /\/(.+)\/(.*)/
      $1
    end

    def options
      text_value.strip =~ /\/(.+)\/(.*)/
      $2
    end

    def case_insensitive?
      options =~ /i/
    end


    def match(target)
      eval( text_value.strip ).match(target)
    end
  end

  module RegexHql
    # Need to escape the predefined character classes since Hive uses the java Regexp to implement its regexp_extract udf
    def escape_for_java(str)
      # We need to do this excessive amount of escaping to get past the subsequent interpolation
      str.gsub('\d', '\\\\\\\\\d').gsub('\D', '\\\\\\\\\D').gsub('\s', '\\\\\\\\\s').gsub('\S', '\\\\\\\\\S').gsub('\w', '\\\\\\\\\w').gsub('\W', '\\\\\\\\\W')
    end

    def to_hql(indent=0)
      return nil unless regex
      src = regex.case_insensitive? ? 'LOWER(' << myapp.placeholder << ')' : myapp.placeholder
      pat = regex.case_insensitive? ? regex.value.downcase : regex.value
      pat = escape_for_java(pat)

      values = format_string.group_refs.collect {|arg| 
       # Substitute for longer references first to avoid replacing subsequences... ie: \1 versus \11
       arg.scan(/\\(\d+)/).sort_by{|a| a.length}.each {|m|
         arg.gsub!("\\#{m.first}", "REGEXP_EXTRACT(#{src}, '#{pat}', #{m.first})") 
       } 
       arg
      }

      "printf('#{format_string.fmt_value}', #{values.join(', ')})"
    end

  end

end

