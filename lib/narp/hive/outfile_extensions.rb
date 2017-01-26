module Narp 
  class Outfile < File

    def hive_write_mode
      (disposition && disposition.value == 'append') ? 
        raise( ArgumentError.new("Appending to an existing output file is currently not supported.") ) :
          'OVERWRITE'
    end

    def stage
      ::File.join([myapp.post_path, name.prefix].compact)
    end

    def stage_dest
      ::File.join(stage, name.basename)
    end

    def hdfs_path
      ::File.join('hdfs:/', myapp.hdfs_out_path, name.to_s)
    end

    def init_post
      [
        "mkdir -p #{stage}"
      ]
    end

    def move_to_post
      ["hadoop fs -getmerge #{hdfs_path} #{stage_dest}",
       "gzip #{stage_dest}"
      ]
    end

    def cleanup 
      [
        "set -e",
        "rm -rf #{stage}", 
        "hadoop fs -rm -r #{hdfs_path}", 
        "set +e"
      ]
    end

    def move_to_s3
      "aws s3 cp #{stage_dest}.gz #{s3_location}"
    end
  
    def insert_sql
      ["INSERT #{hive_write_mode} TABLE #{table_name}",
       "SELECT\n\t" << sql_cols.join("\n\t, "), 
       where_clause
      ].compact.join("\n")
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

  end
end
