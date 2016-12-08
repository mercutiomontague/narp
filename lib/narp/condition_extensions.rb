require 'narp/basic_extensions.rb'

module Narp

  class NumericTerminal < Treetop::Runtime::SyntaxNode
  end

  class ArithmeticOperator < TerminalNode
  end

  class NumericOperator < TerminalNode
    def value
      case text_value.downcase.strip
        when '=', 'eq'
          '='
        when '!=', 'ne'
          '!='
        when '<', 'lt'
          '<'
        when '>', 'gt'
          '>'
        when '<=', 'le'
          '<='
        when '>=', 'ge'
          '>='
      end  
    end
  end

  class NumericExpression < Treetop::Runtime::SyntaxNode
  end

  class CharacterTerminal < Treetop::Runtime::SyntaxNode
  end

  class MatchOperator < TerminalNode
  end

  class CharacterOperator < TerminalNode
  end

  class LogicalOperator < TerminalNode
    def to_s
      value.upcase
    end
  end

  class CharacterExpression < Treetop::Runtime::SyntaxNode
    attribute MatchOperator, CharacterOperator, Regex, CharacterExpression
    attributes CharacterTerminal
  
    def string_hql_expression
      return nil if regex
      return character_terminals.first.to_hql unless (character_operator || match_operator)
      op = (character_operator || match_operator).value 
      case op
        when 'ct'
          "LOCATE( #{character_terminals.last.to_hql}, #{character_terminals.first.to_hql}) > 0" 
        when 'nc'
          "LOCATE( #{character_terminals.last.to_hql}, #{character_terminals.first.to_hql} ) = 0"
        when 'mt'
          "#{character_terminals.first.to_hql} = #{character_terminals.last.to_hql}" 
        when 'nm'
          "#{character_terminals.first.to_hql} <> #{character_terminals.last.to_hql}" 
        when '+'
          "CONCAT(#{character_terminals.first.to_hql}, #{character_expression.to_hql})"
        else
          "#{character_terminals.first.to_hql} #{op} #{character_terminals.last.to_hql}" 
      end
    end

    def regex_hql_expression
      return nil unless regex
      lhs = regex.case_insensitive? ? "LOWER(#{character_terminals.first.to_hql})" : character_terminals.first.to_hql
      rhs = regex.case_insensitive? ? regex.value.downcase : regex.value
      case match_operator.value
      when 'mt'
        "#{lhs} RLIKE '#{rhs}'"
      when 'mn'
        "NOT #{lhs} RLIKE '#{rhs}'"
      end
    end

    def to_hql(indent=0)
      string_hql_expression || regex_hql_expression
    end
  end

  class Expression < Treetop::Runtime::SyntaxNode
  end

  class Condition < NamedNode
    def to_s 
      # mysearch( Expression, LogicalOperator, ParenthesisLiteral ).collect{|s| s.to_s}.join(' ').squeeze(' ').gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
      mysearch( Expression, LogicalOperator, ParenthesisLiteral ).collect{|s| s.to_s}.join(' ').gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
    end

    # Convert the condition into hql, taking particular care with regular expressions
    def to_hql
      # mysearch( Expression, LogicalOperator, ParenthesisLiteral ).collect{|s| s.to_hql}.join(' ').squeeze(' ').gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
      mysearch( Expression, LogicalOperator, ParenthesisLiteral ).collect{|s| s.to_hql}.join(' ').gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
    end
  end

end  



