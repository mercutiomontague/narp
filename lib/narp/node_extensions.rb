module AppPosition
  def position=(num)
    @position=num
  end
  def position
    @position || 0
  end
  def parent=(parent)
    @parent = parent
  end
  def parent
    @parent
  end
  def next_position
    parent._next_position(@position)
  end
end

class PositionalList < Array
  def <<(*others)
    others.flatten.each {|e|
      e.extend( AppPosition )
      e.parent = self
      e.position = myapp.next_sequence
      push e
    }
  end

  # Return the next largest value
  def _next_position(val)
    collect{|c| c.position > val ? c.position : nil}.compact.min
  end
end

class MockObject < OpenStruct
  def initialize( target, *arg )
    @target = target
    super(*arg)
  end

  def is_a?( other )
    @target == other
  end
end

module Narp
  class ParseError < Exception
  end
end

class String
  def to_method_name
    class_name = split('::').last
    class_name.gsub(/([A-Z]+)/, '_\1'.downcase).sub(/^_/, '').downcase
  end
  
  def to_filename
    to_method_name
  end

  def myindent(num=1)
    return self unless num > 0
    tabs = "\t" * num
    tabs.dup <<  split("\n").join("\n#{tabs}")
  end

  def sql_justify_on_alias
    pieces = split("\n").collect{|line| 
      line =~ /^(.+)\s+AS (.+?)$/ 
      # raise ArgumentError.new("I am expecting lines with 'AS alias' but I got:\n#{self}") unless $1 && $2
      return self unless $1 && $2
      [$1, $2]
    }

    max_len = [80, pieces.collect{|ar| ar.first.length}.max + 8].min
    pieces.collect{|ar| ar.first << ' ' * (ar.first.length < max_len ? max_len - ar.first.length : 8) << 'AS ' << ar.last}.join("\n")
  end
end

class DualIterator < Array
  def initialize(objs1, objs2)
    o2 = objs2.to_a
    objs1.each_with_index {|o, i|
      push [o, o2[i]]
    }
  end
end



# Define some custom attributes to simplify creatoin
# of custom SyntaxNode subclasses.
class Class 

  def attribute_definer( ar, match_type = 'myfind' )
    ar.each {|at|
      class_name, class_obj, meth_name = '', '', ''
      if at.respond_to?(:each)
        class_obj, meth_name = at.first, at.last.to_s
       else
         # insert an underscore before each cap, except the first
         # class_name = at.to_s.split('::').last
         # meth_name = class_name.gsub(/([A-Z]+)/, '_\1'.downcase).sub(/^_/, '').downcase
         meth_name = at.to_s.to_method_name 
         class_obj = at
       end
      self.class_eval(
        "def #{meth_name}; #{match_type}( #{class_obj} ); end"
      )
    }
  end

  def attribute( *ar )
    attribute_definer( ar )
  end

  def attributes( *ar )
    ar2 = ar.collect{|elem| 
      if elem.is_a?(Array) 
        elem
      else
        [elem, "#{elem.to_s.to_method_name}s"]
      end
    }
    attribute_definer( ar2, 'mysearch' )
  end
end


# Define some finders to make it easy to bring child elements
class Treetop::Runtime::SyntaxNode
	def value
		text_value.strip.downcase
	end

  def to_s
    (elements && elements.size > 0 && elements.collect{|f| f.to_s }.join(' ')) || value
  end

  def to_hql(indent=0)
    (elements && elements.size > 0 && elements.collect{|f| f.to_hql(indent) }.reject{|r| r == ''}.join(' ')) || value
  end

  # def to_column_expression(indent=0)
  #   to_hql(indent)
  # end

  def myfind( class_obj )
    return self if self.class == class_obj 
    return nil unless elements

    n = elements.detect {|d| d.class == class_obj }
    return n if n          
   
    elements.each {|e|
      [e.elements].flatten.compact.each {|c|
        return c.myfind( class_obj ) if c.myfind( class_obj )
      }
    } 
    nil
  end

  def mysearch( *class_objs)
    return [self] if class_objs.detect{|o| self.class == o} 
    res = elements.collect {|d| 
      if class_objs.detect{|o| d.class == o}
        d
      else
        d.elements && d.elements.collect{|e| e.mysearch(*class_objs) }
      end
    }.flatten.compact
  end

  # This method is useful for supporting mockups 
  def class_name
    self.class.to_s
  end

end

module Narp
  module MyAppAccessor
    def method_missing(meth, *arg, &block)
      if myapp.respond_to?(meth)
        myapp.send(meth, *arg, &block)
      else
        raise ScriptError.new("Undefined method #{meth}")
      end
    end
  end
end
