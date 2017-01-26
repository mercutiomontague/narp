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

    def record_numbering_sql
      "ROW_NUMBER() OVER () + #{record_numbering && record_numbering.value} -1 AS row_num" 
    end

    def sql_cols
      file_fields.collect{|r|
        field = r.respond_to?(:name) ? r.name : r
        if field == 'row_num' 
          record_numbering_sql 
        else 
          field =~ /^rhs_|^lhs_/ ? field : "lhs_#{field}"
        end
      }
    end

    def where_clause
      conditions.empty? ? nil : "WHERE\n\t" << conditions.collect{|c| c.to_sql }.join("\n\tAND ") 
    end

    def s3_location
      ::File.join(myapp.s3_out_bucket_url, name.s3_prefix, ::File.basename(target))
    end

  end

  class OutfileList < FilesList
  end
  
end
