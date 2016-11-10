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
      z = myapp.output_spec.column_names_for(self)
      record_numbering ? z.unshift( 'row_num' ) : z
    end

    def fields_string
      # Remove the prefixes
      file_fields.collect{|i| "#{i.gsub(/^lhs_|rhs_/,'')} varchar(65000)"}.join("\n\t, ") 
    end

    def select_column_names 
      z = myapp.output_spec.column_names_for(self)
      record_numbering ? z.unshift( "ROW_NUMBER() OVER () + #{record_numbering && record_numbering.value} AS row_num") : z
    end

    def stage
      myapp.post_stage_path
    end

    def work
      myapp.post_path
    end

    def populate_hql
      ["INSERT #{hive_write_mode} TABLE #{hive_name}",
       "SELECT\n\t" << select_column_names.join("\n\t, "), 
       conditions.empty? ? nil : "WHERE\n\t" << conditions.collect{|c| c.to_hql }.join("\n\tAND ") 
      ].compact.join("\n")
    end

    def move_hdfs2post_stage
      "hadoop fs -getmerge #{hdfs_path} #{stage}/#{name}"
    end

    def post_process
      warn("Minimum record lengths are not yet implimented and was ignored for [#{name}]") if record_length && record_length.min > 1
      [record_length.nil? ?
        "mv #{stage}/#{name} #{work}/#{name}" :
          "cut -c1-#{record_length.max} #{stage}/#{name} > #{work}/#{name}",
        "gzip #{work}/#{name}"
      ]
    end

    def cleanup 
      [
        "set +e",
        "rm #{stage}/#{name}", 
        "rm #{work}/#{name}.gz",
        "rm #{work}/#{name}",
        "hadoop fs -rmr #{hdfs_path}", 
        "set -e"
      ]
    end

    def move_post2s3
      "aws s3 cp #{work}/#{name}.gz #{myapp.s3_out_path}/#{name}.gz"
    end
  end

  class OutfileList < FilesList
  end
  
end

