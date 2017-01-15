require 'narp/node_extensions.rb'
require 'narp/sql/adapter.rb'
require 'narp/sql/source.rb'

module Narp
  module Hive

    # This class handles the generation of the ddl and hql for for transforming
    # flat files with Hive
    class Adapter < ::Narp::Sql::Adapter
      include MyAppAccessor

      def set_options
        "set hive.groupby.orderby.position.alias = true;"
      end

      def sql
        set_options << "\n\n" <<
        use_db << "\n\n" <<
        "FROM (\n#{data_source}\n)src\n" << 
        outfiles.collect{|o| o.insert_sql }.join("\n\n") << "\n;"
      end

    end
  end
end
