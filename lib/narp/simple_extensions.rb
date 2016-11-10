require 'node_extensions.rb'
require 'basic_extensions.rb'

module Narp
  class Join < Treetop::Runtime::SyntaxNode
    def value 
      w = text_value.strip.squeeze(" \t").downcase.sub(/\/join unpaired\s*/, '')
      case w
      when 'leftside'
        'left join'
      when 'rightside'
        'right join'
      when 'leftside only'
        'left not in'
      when 'rightside only' 
        'right not in'
      when 'leftside rightside', ''
        'full join'
      when 'leftside rightside only', 'only'
        'xor'
      end
    end
  end

  class Copy < TerminalNode
  end

  class CollatingSequence < TerminalNode
    attribute [MyIdentifier, :myid]

    def name
      myid && myid.value || 'default'
    end

    def base_sequence
      'ascii'
    end

  end

end
