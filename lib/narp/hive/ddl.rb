require 'narp/node_extensions.rb'
# require 'digest'

module Narp
  module Hive
    module DDL
      def ddl
        raise ArgumentError.new("The file type #{organization.value} isn't currently supported") unless organization.nil? || organization.value == 'sequential'
        # %Q[SET textinputformat.record.delimiter="#{line_seperator}";\n] << 
        "CREATE EXTERNAL TABLE #{table_name}\n(\n" <<
        "\t" << fields_string <<
        "\n)\n" <<
        "ROW FORMAT\n" <<
        "\tDELIMITED FIELDS TERMINATED BY '#{field_seperator.escaped_value}'\n" <<
        "\tLINES TERMINATED BY '\n'" <<
        "\tNULL DEFINED AS ''\n" <<
        "STORED AS TEXTFILE\n" <<
        "LOCATION '#{remote_location}/'\n;"
      end
    end
  end
end
