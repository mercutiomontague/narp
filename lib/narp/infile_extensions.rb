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
      (_number_of_columns || 5).to_i
    end

    def file_fields
      (1 .. number_of_columns).collect{|i| 
        OpenStruct.new(name: myapp.column_name(i), to_column_expression: myapp.column_name(i))
      }
    end

    def hive_name
      nick_name
    end

    def nick_name
      @nick_name ||= (nick && nick.name) || "in_#{myapp.next_sequence}"
    end

		def field_seperator
			_field_seperator || File::default_field_seperator
		end

    def stage
      ::File.join(myapp.pre_stage_path, name.prefix)
    end

    def work
      ::File.join(myapp.pre_path, name.prefix)
    end

    def compute_number_of_columns 
      # Process the first line to determine the number of records. RS == record seperator, FS = field seperator
      # awk -v RS='\r' -v FS='\t' 'NR==1'  features/fixtures/data_2016-11-03.txt | awk -F '\t' '{print NF}' 
      ["col_cnt=`#{awk_preamble} 'NR==1 {print NF}' #{work}/#{uncompressed_basename}`", 
        "echo /infile #{name.to_s} NUMBER_OF_COLUMNS $col_cnt"
      ].join(" && ")
    end

    def init_pre
      [
        "hadoop fs -mkdir -p #{hdfs_path}", 
        "mkdir -p #{stage}",
        "mkdir -p #{work}"
      ]
    end

    def cleanup
      [
        "rm -rf #{stage}",
        "hadoop fs -rm -r #{hdfs_path}"
      ]
    end

    def move_s32pre_stage
      [
       "aws s3 cp #{::File.join(myapp.s3_in_path, compressed_name)} #{stage}/#{compressed_basename}",
       compression_type == :gz ? "gunzip -f #{stage}/#{compressed_basename}" : "unzip -o #{stage}/#{compressed_basename}"
      ]
    end

    # awk to process a text file with record and field seperator defined
    def awk_preamble
      "awk -v RS='#{line_seperator}' -v FS='#{field_seperator.escaped_value}' "
    end

    # Extract the lines that need processing or just a symlink to the original file if no work is needed
    def pre_process
      warn("Minimum record lengths are not yet implimented and was ignored for [#{name}]") if record_length && record_length.min > 1
      if skip_to.nil? && stop_after.nil? && record_length.nil?
        "ln -s #{stage}/#{uncompressed_basename} #{work}/#{uncompressed_basename}"
      else
        # awk -v RS='\r' -v FS='\t' 'NR=>1 && NR<=4'  features/fixtures/data_2016-11-03.txt
        ops = [skip_to ? "NR >= #{skip_to.value}" : nil,
                stop_after ? "NR <= #{stop_after.value}" : nil
              ].compact
        cmd = [awk_preamble, ops.join(' && '), "<< #{stage}/#{uncompressed_basename}"].join(' ')

        cmd << " | cut -c1-#{record_length && record_length.max}" if record_length
        cmd << " > #{work}/#{uncompressed_basename}\n"

      end
    end

    def analyze
      return if _number_of_columns      
      compute_number_of_columns
    end

    def move_pre2hdfs
      "hadoop fs -copyFromLocal #{work}/#{uncompressed_basename} #{hdfs_path}/"
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
        "#{hive_name}"
    end

  end

  class InfileList < FilesList
    def s3_path_prefix
      myapp.s3_in_path
    end

    def lhs_tables
      select{|s| s.side == :lhs }
    end
  
    def rhs_tables
      select{|s| s.side == :rhs }
    end
  end
end  
