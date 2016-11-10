module Narp
  class SyntaxTree
    require 'treetop'
    def initialize(grammar_class)
      @parser = ''
    	Treetop.load(::File.expand_path(::File.join(::File.dirname(__FILE__), "#{grammar_class.to_filename}.treetop")))
      eval( "@parser = #{grammar_class}Parser.new " )
    end
    
    def parse(input)
      tree = @parser.parse(input)
      
      if(tree.nil?)
        raise ParseError.new( "Error attempting to parse #{input}.\nParse error: #{@parser.failure_reason} at offset: #{@parser.index}\n#{parse_issue.message}") 
      end
      
      # clean up the tree by removing all nodes of default type 'SyntaxNode'
      clean_tree(tree)
      
      return tree
      rescue RegexpError, ArgumentError => ex
        raise ParseError.new( "Error attempting to parse #{input}.\n#{ex.message}\nParse error: #{@parser.failure_reason} at offset: #{@parser.index}") 
    end
    
    
    def clean_tree(node)
      return if(node.elements.nil?)
      node.elements.each {|node| self.clean_tree(node) }
      # Remove a node if it is a boring SyntaxNode and all of its descendants are Syntaxnodes
      node.elements.delete_if{|node| node.class.name == "Treetop::Runtime::SyntaxNode" && node.elements.nil? }
    end
  
  end
end 
