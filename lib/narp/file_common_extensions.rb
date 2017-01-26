require 'narp/node_extensions.rb'
# require 'digest'

module Narp

  class FileIdentifier < TerminalNode
    def value
      text_value.strip
    end

    def prefix
      ::File.dirname(value) == '.' ? nil : ::File.dirname(value)
    end

    # Create a folder with the filename but omitting the last extension.
    def s3_prefix
      p = ::File.basename(value).split('.')[0..-2].join('.')
      [prefix, p].compact.join('/')
    end

    def basename
      ::File.basename(value)
    end

  end

  class FileAttribute < Treetop::Runtime::SyntaxNode
  end

  class Organization < Treetop::Runtime::SyntaxNode
  end
  
  class Compressed < Treetop::Runtime::SyntaxNode
    def value
      if text_value.strip =~ /^compressed$/i
        'normal'
      elsif text_value.strip =~ /^compressed highcompression$/i
        'high'
      elsif  text_value.strip =~ /^uncompressed$/i
        'none'
      else
        raise ArgumentError.new("Unknown compression value #{text_value}")
      end
    end
  end
  
  class StreamRecordFormat < TerminalNode
    attribute String
    
    def escaped_value
      return string.escaped_value if string
      text_value.strip.downcase =~ /stream\s+(.+)/
      case $1 && $1.intern
        when :cr
          '\r'
        when :lf
          '\n'
        when :crlf
          '\r\n'
        else 
          '\n'
      end
    end

    def value
      return string if string
      text_value.strip.downcase =~ /stream\s+(.+)/
      case $1.intern
        when :cr
          "\r"
        when :lf
          "\n"
        when :crlf
          "\r\n"
      end
    end

  end

  class FieldSeperator < Narp::String
  end

  class RecordLength < Treetop::Runtime::SyntaxNode
    def max 
      pieces.size == 2 ? pieces.max : pieces.first
    end

    def min
      pieces.size == 2 ? pieces.min : 0
    end

    def pieces
      text_value.split(/\s+/).collect{|c| c.to_i}
    end
  end

  class File < Treetop::Runtime::SyntaxNode
    attribute [FileIdentifier, :name]
    attribute Organization, RecordLength, Compressed, [FieldSeperator, :_field_seperator]
    attribute StreamRecordFormat

    def compressed_name 
      name.value =~ /\.zip$|\.gz$/ ? name.value : "#{name.value}.gz"
    end

    def uncompressed_name
      name.value.sub(/\.zip$|\.gz$/, '') 
    end

    def compressed_basename 
      ::File.basename(compressed_name)
    end

    def uncompressed_basename
      ::File.basename(uncompressed_name)
    end

		def self.default_field_seperator
			OpenStruct.new(:escaped_value => '\t', :to_s => "\t")
		end

    def line_seperator
      stream_record_format && stream_record_format || "\n"
    end

    def fields_string
      file_fields.collect{|i| "#{i.respond_to?(:name) ? i.name : i.to_s} varchar(65000)"}.join("\n\t, ") 
    end

    def table_name
      @table_name ||= [myapp.domain, "t_#{myapp.next_sequence}"].join('.')
    end

    def drop_ddl
      "DROP TABLE #{table_name};"
    end

  end

  class FilesList < PositionalList
    def s3_mappings
      inject( {} ) { |memo, item| 
        memo[ item.name.value ] = item.s3_location
        memo
      }
    end 
  end

end
