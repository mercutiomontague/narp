require 'narp/node_extensions.rb'
require 'narp/hive/source.rb'

module Narp
  module Sql 

    # This class handles the generation of the ddl and hql for for transforming
    # flat files with Hive
    class Adapter
      include MyAppAccessor

      def use_db
        "USE #{domain};"
      end

      def drop_db
        "DROP DATABASE #{domain};"
      end

  	  def ddl
        ["CREATE DATABASE #{domain};", 
  	  	[infiles.collect{|i| i.ddl}, outfiles.collect{|f| f.ddl}]].flatten.join("\n\n")
  	  end

      def cleanup_db
        [use_db, [infiles, outfiles].flatten.collect{|f| f.drop_ddl}, drop_db].flatten.join("\n")
      end

      def data_source
        ::Narp::Sql::Source.new.to_s
      end
    end
  end
end
