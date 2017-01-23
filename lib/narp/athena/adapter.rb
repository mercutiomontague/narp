require 'narp/node_extensions.rb'
require 'narp/sql/adapter.rb'

module Narp
  module Athena 

    # This class handles the generation of the ddl and hql for for transforming
    # flat files with Hive
    class Adapter < ::Narp::Sql::Adapter
      include ::Narp::MyAppAccessor

      def sql
        outfiles.collect{|o|
          ["WITH (\n#{data_source}\n) AS src", 
           "SELECT\n\t", 
           o.sql_cols.join("\n\t"), 
           "FROM src", 
           where_clause
          ].compact.join("\n")
        }
      end
    end
  end
end
