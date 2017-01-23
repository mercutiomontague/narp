require 'narp/node_extensions.rb'

module Narp
  class Alias < NamedNode
  end

  class SkipTo < IntegerNode
  end

  class StopAfter < IntegerNode
  end

  class NumberOfColumns < IntegerNode
    def to_i
      to_s.to_i
    end
  end

  class Infile < File
    attribute [Alias, :nick], SkipTo, StopAfter, [NumberOfColumns, :_number_of_columns]

    def compression_type
      name.value =~ /\.zip$/ ? :zip : :gz
    end

    def number_of_columns
      # (_number_of_columns || 5).to_i
      _number_of_columns.to_i
    end

    def file_fields
      (1 .. number_of_columns).collect{|i| 
        OpenStruct.new(name: myapp.column_name(i), to_column_expression: myapp.column_name(i))
      }
    end

    def table_name
      @table_name ||= [myapp.domain,  nick_name || "in_#{myapp.next_sequence}"].join('.')
    end

    def nick_name
      nick && nick.name
    end

		def field_seperator
			_field_seperator || File::default_field_seperator
		end

    # Partition the tables into 'left' and 'right' side tables based on their location relative to joinkeys.
    # Those before the first are left and those after are right
    def side 
      myapp.joinkeys.any? && position > myapp.joinkeys.first_position ? :rhs  : :lhs
    end

    def base_fields
      if myapp.copy 
        [file_fields, myapp.fields].flatten
      else
        myapp.fields
      end
    end

    def base_sql 
      "SELECT\n" << 
        ("\t" << base_fields.collect{|f| f.to_column_expression}.join("\n\t, ")).sql_justify_on_alias << "\n" <<
      "FROM\n\t" <<
        "#{table_name}"
    end

    def s3_path_prefix
      myapp.s3_in_path
    end

  end

  class InfileList < FilesList
    def lhs_tables
      select{|s| s.side == :lhs }
    end
  
    def rhs_tables
      select{|s| s.side == :rhs }
    end
  end
end  
