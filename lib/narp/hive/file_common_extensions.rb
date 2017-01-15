require 'narp/node_extensions.rb'
# require 'digest'

module Narp

  # Add hive specific capabilities
  class File < Treetop::Runtime::SyntaxNode

    def hdfs_path
      ::File.join('hdfs:/', myapp.hdfs_in_path, uncompressed_name)
    end

    def remote_location
      hdfs_path
    end

  end

end
