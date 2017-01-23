require 'narp/node_extensions.rb'
require 'narp/hive/ddl.rb'


module Narp

  # Add hive specific capabilities
  class File < Treetop::Runtime::SyntaxNode
    include Hive::DDL

    def hdfs_path
      ::File.join('hdfs:/', myapp.hdfs_in_path, uncompressed_name.gsub(/'|"/, ''))
    end

    def remote_location
      hdfs_path
    end

  end

end
