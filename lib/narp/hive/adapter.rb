require 'narp/node_extensions.rb'
require 'narp/hive/source.rb'

module Narp
  module Hive

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
         use_db, 
  	  	[infiles.collect{|i| i.ddl}, outfiles.collect{|f| f.ddl}]].flatten.join("\n\n")
  	  end

      def cleanup_db
        [use_db, [infiles, outfiles].flatten.collect{|f| f.drop_ddl}, drop_db].flatten.join("\n")
      end

      def hql
        use_db << "\n\n" <<
        "FROM (\n#{Source.new.to_s.myindent}\n)src\n" << 
        outfiles.collect{|o| o.populate_hql }.join("\n\n") << "\n;"
      end

    end
  end
end
