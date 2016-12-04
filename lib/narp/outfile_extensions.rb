module Narp 
  class Disposition < Treetop::Runtime::SyntaxNode
  end
  
  class RecordNumbering < Treetop::Runtime::SyntaxNode
		def value
			text_value =~ /recordnumber\s+(?:start\s+)?\s*(\d+)/i
			($1 || 1).to_i
		end 
  end

  class Outfile < File
   	attribute Disposition, RecordNumbering

    def hive_write_mode
      (disposition && disposition.value == 'append') ? 
        raise( ArgumentError.new("Appending to an existing output file is currently not supported.") ) :
          'OVERWRITE'
    end

    def conditions
      myapp.includes.applicables(self)
    end

		def field_seperator
			_field_seperator || myapp.first_explicit_field_seperator || File::default_field_seperator
		end

    def file_fields
      z = if myapp.copy
        [myapp.lhs_tables.first.file_fields,
          myapp.rhs_tables.empty? ? nil : 
            myapp.rhs_tables.first.file_fields.collect{|f| OpenStruct.new(name: "rhs_" << f.name)}
        ].flatten.compact
      else
        myapp.output_spec.column_names_for(self)
      end

      record_numbering ? z.unshift( OpenStruct.new(name: 'row_num')) : z
    end

    def stage
      ::File.join([myapp.post_stage_path, name.prefix].compact)
    end

    def stage_dest
      ::File.join(stage, name.basename)
    end

    def hdfs_path
      ::File.join('hdfs:/', myapp.hdfs_out_path, name.to_s)
    end

    def hdfs_post_process_path
      ::File.join('hdfs:/', myapp.hdfs_out_path, name.to_s, 'post_process')
    end

    def record_numbering_sql
      "ROW_NUMBER() OVER () + #{record_numbering && record_numbering.value} -1 AS row_num" 
    end

    def populate_hql
      cols = file_fields.collect{|r|
        field = r.respond_to?(:name) ? r.name : r
        if field == 'row_num' 
          record_numbering_sql 
        else 
          field =~ /^rhs_/ ? field : "lhs_#{field}"
        end
      }.join("\n\t, ")

      ["INSERT #{hive_write_mode} TABLE #{hive_name}",
       "SELECT\n\t" << cols,
       conditions.empty? ? nil : "WHERE\n\t" << conditions.collect{|c| c.to_hql }.join("\n\tAND ") 
      ].compact.join("\n")
    end

    def init_post
      [
        "mkdir -p #{stage}"
      ]
    end

    # If we post-processed the data (ie: by changing the row delimiter or cutting the record length) then
    # the source path is different
    def move_hdfs2post_stage
      ["hadoop fs -getmerge #{post_process ? hdfs_post_process_path : hdfs_path} #{stage_dest}",
       "gzip #{stage_dest}"
      ]
    end

    def post_process
      warn("Minimum record lengths are not yet implimented and was ignored for [#{name}]") if record_length && record_length.min > 1

      return nil unless fix_row_delimiter || fix_row_length
      ["hadoop fs -cat #{hdfs_path}/*", fix_row_length, fix_row_delimiter, "hadoop fs -put - #{hdfs_post_process_path}"].compact.join(' | ')
    end

    def fix_row_delimiter
      if line_seperator == '\r'
        %q{sed 's/$/\r/g' | tr -d '\n'} 
      elsif line_seperator == '\r\n'
        %q{sed 's/$/\r/g'} 
      end
    end

    def fix_row_length
      "cut -c1-#{record_length.max}" if record_length
    end

    def cleanup 
      [
        "set -e",
        "rm -rf #{stage}", 
        "hadoop fs -rm -r #{hdfs_path}", 
        "set +e"
      ]
    end

    def move_post2s3
      "aws s3 cp #{stage_dest}.gz #{::File.join(myapp.s3_out_path, name.to_s)}.gz"
    end
  end

  class OutfileList < FilesList
    def s3_path_prefix
      myapp.s3_out_path
    end
  end
  
end
