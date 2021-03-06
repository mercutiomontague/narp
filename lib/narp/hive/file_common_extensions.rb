require 'narp/node_extensions.rb'
require 'narp/hive/ddl.rb'


module Narp

  # Add hive specific capabilities
  class File < Treetop::Runtime::SyntaxNode
    include Hive::DDL

    def remote_location
      hdfs_path
    end

  end

end
