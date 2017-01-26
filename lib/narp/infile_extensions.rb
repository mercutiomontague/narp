require 'narp/node_extensions.rb'
require 'aws-sdk'

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

    def to_normalized
      super =~ /number_of_columns/i ? super : super << " number_of_columns #{number_of_columns}"
    end

    # Compute the number of columns using the lambda service
    def compute_number_of_columns 
      @numcols ||=  
        begin
          lam = Aws::Lambda::Client.new( { region: 'us-east-1' } )
          resp = lam.invoke(function_name: 'NumberOfColumns', 
                            qualifier: 'Prod', 
                            payload: JSON.generate( {'Bucket': myapp.s3_in_bucket_uri,
                                                     'Prefix': name.s3_prefix, 
                                                     'FieldDelimiter': field_seperator.to_s, 
                                                     'LineDelimiter': line_seperator.to_s }
                                                  )
                           )
          raise Exception.new("Invocation Error! #{JSON.parse(resp['payload'].read)['errorMessage']}" ) if resp['function_error']

          resp['payload'].read 
        end
    end

    def number_of_columns
      # (_number_of_columns || 5).to_i
      (_number_of_columns && _number_of_columns.to_i) || compute_number_of_columns
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

    def s3_location
      target = (name.to_s =~ /\.gz$|\.zip$/ ? name.to_s : name.to_s << ".gz")
      ::File.join(myapp.s3_in_bucket_url, name.s3_prefix, ::File.basename(target))
    end



    # # awk to process a text file with record and field seperator defined
    # def awk_preamble
    #   "awk -v RS='#{line_seperator}' -v FS='#{field_seperator.escaped_value}' "
    # end

    # Extract just the lines that need processing 
    def pre_process
      warn("Minimum/Maximum record lengths for infile are not yet implimented and was ignored for [#{name}]") if record_length 
      warn("'Skip to' and 'Stop after' for infile are not yet implimented and was ignored for [#{name}]") unless skip_to.nil? && stop_after.nil?


      # if skip_to.nil? && stop_after.nil? && record_length.nil?
      #   "ln -s #{stage}/#{uncompressed_basename} #{work}/#{uncompressed_basename}"
      # else
      #   # awk -v RS='\r' -v FS='\t' 'NR=>1 && NR<=4'  features/fixtures/data_2016-11-03.txt
      #   ops = [skip_to ? "NR >= #{skip_to.value}" : nil,
      #           stop_after ? "NR <= #{stop_after.value}" : nil
      #         ].compact
      #   cmd = [awk_preamble, ops.join(' && '), "< #{stage}/#{uncompressed_basename}"].join(' ')

      #   cmd << " | cut -c1-#{record_length && record_length.max}" if record_length
      #   cmd << " > #{work}/#{uncompressed_basename}\n"

      # end
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
