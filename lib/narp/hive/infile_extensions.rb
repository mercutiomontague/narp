require 'narp/node_extensions.rb'

module Narp
  class Infile < File
    def hdfs_path
      ::File.join('hdfs:/', myapp.hdfs_in_path, uncompressed_name.gsub(/'|"/, ''))
    end


    def init_pre
      [
        "hadoop fs -mkdir -p #{hdfs_path}", 
        "mkdir -p #{::File.join(myapp.pre_path, name.prefix)}",
      ]
    end

    def cleanup
      [
        "rm -rf #{myapp.pre_path}",
        "hadoop fs -rm -r #{hdfs_path}"
      ]
    end

    def move_to_hdfs
      local_name = ::File.join(myapp.pre_path, name.prefix, compressed_basename)
      uncompressed_local_name = ::File.join(myapp.pre_path, name.prefix, uncompressed_basename)
      [
       "aws s3 cp #{s3_location} #{local_name}", 
       compression_type == :gz ? "gunzip -f #{local_name}" : "unzip -o #{local_name}", 
       "hadoop fs -copyFromLocal #{uncompressed_local_name} #{hdfs_path}/"
      ]
    end

  end

end  
