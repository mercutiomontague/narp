require 'narp/node_extensions.rb'

module Narp
  class Alias < NamedNode
  end

  class SkipTo < IntegerNode
  end

  class StopAfter < IntegerNode
  end

  class NumberOfColumns < IntegerNode
  end

  class Infile < File
    attribute [Alias, :nick], SkipTo, StopAfter, [NumberOfColumns, :_number_of_columns]

    def number_of_columns
      _number_of_columns || inferred_column_count
    end

    def inferred_column_count
      8
    end

    def file_fields
      (1 .. inferred_column_count).collect{|c| OpenStruct.new(:name => myapp.column_name(c))}
    end

    def hive_name
      # "#{schema}.#{nick_name}" 
      nick_name
    end

    def nick_name
      @nick_name ||= (nick && nick.name) || "in_#{myapp.next_sequence}"
    end

		def field_seperator
			_field_seperator || File::default_field_seperator
		end

    def stage
      myapp.pre_stage_path
    end

    def work
      myapp.pre_path
    end

    def analyze
			# head -1 data_2016-11-03.txt | awk -F '\t' '{print NF}'
    end

    def init_pre
      [
        "hadoop fs -mkdir #{hdfs_path}", 
      ]
    end

    def cleanup
      [
        "set +e",
        "rm #{stage}/#{name}.gz",
        "rm #{stage}/#{name}", 
        "rm #{work}/#{name}",
        "hadoop fs -rmr #{hdfs_path}", 
        "set -e"
      ]
    end

    def move_s32pre_stage
      ["aws s3 cp #{myapp.s3_in_path}/#{name}.gz #{stage}/#{name}.gz",
       "gunzip #{stage}/#{name}.gz" 
      ]
    end

    # Extract the lines that need processing or just a symlink to the original file if no work is needed
    def pre_process
      warn("Minimum record lengths are not yet implimented and was ignored for [#{name}]") if record_length && record_length.min > 1
      if skip_to.nil? && stop_after.nil? && record_length.nil?
        "ln -s #{stage}/#{name} #{work}/#{name}"
      else
        ops = [skip_to ? "tail -$((tot - #{skip_to.value}))" : nil, 
         stop_after ? "head -#{stop_after.value}" : nil,
         record_length ? "cut -c1-#{record_length && record_length.max}" : nil
        ].compact
        ops[0] = ops.first << " #{stage}/#{name}"

        "tot=`wc -l #{stage}/#{name} | cut -f1 -d' '\n" << ops.join(" | ") << " > #{work}/#{name}\n"
      end
    end

    def move_pre2hdfs
      "hadoop fs -copyFromLocal #{work}/#{name} #{hdfs_path}"
    end

    # Partition the tables into 'right' and 'right' side tables based on their location relative to joinkeys.
    # Those before the first are right and those after are right
    def side 
      myapp.joinkeys.any? && position > myapp.joinkeys.first_position ? :rhs  : :lhs
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
