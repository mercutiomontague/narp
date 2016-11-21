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

    def number_of_columns
      (_number_of_columns || compute_number_of_columns).to_i
    end

    def file_fields
      @file_fields ||= (1 .. number_of_columns).collect{|i| 
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
			# head -1 data_2016-11-03.txt | awk -F '\t' '{print NF}'
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
       "aws s3 cp #{::File.join(myapp.s3_in_path, name.to_s)}.gz #{stage}/#{name.basename}.gz",
       "gunzip -f #{stage}/#{name.basename}.gz"
      ]
    end

    # Extract the lines that need processing or just a symlink to the original file if no work is needed
    def pre_process
      warn("Minimum record lengths are not yet implimented and was ignored for [#{name}]") if record_length && record_length.min > 1
      if skip_to.nil? && stop_after.nil? # && record_length.nil?
        "ln -s #{stage}/#{name.basename} #{work}/#{name.basename}"
      else
        ops = [skip_to ? "tail -$((tot - #{skip_to.value}))" : nil, 
         stop_after ? "head -#{stop_after.value}" : nil,
         record_length ? "cut -c1-#{record_length && record_length.max}" : nil
        ].compact
        ops[0] = ops.first << " #{stage}/#{name.basename}"

        "tot=`wc -l #{stage}/#{name.basename} | cut -f1 -d' '\n" << ops.join(" | ") << " > #{work}/#{name.basename}\n"
      end
    end

    def move_pre2hdfs
      "hadoop fs -copyFromLocal #{work}/#{name.basename} #{hdfs_path}/"
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
    def lhs_tables
      select{|s| s.side == :lhs }
    end
  
    def rhs_tables
      select{|s| s.side == :rhs }
    end
  end
end  
