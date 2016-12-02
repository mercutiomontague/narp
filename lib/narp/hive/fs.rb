require 'narp/node_extensions.rb'

module Narp
  module Hive

    # This class handles the pre/post processing of the data files before/after
    # the Hive processing
    class Fs 
      include MyAppAccessor

      def exit_on_error
        "set -e"
      end

      def no_exit_on_error
        "set +e"
      end

      def bash_script_header
        ["#!/bin/bash\n", exit_on_error].join("\n")
      end

      def preprocess
        # Unzip, Extract the necessary lines (:%s/skipto, stopafter) and finally put the files where HIVE can find them.
        infiles.collect{|i| [bash_script_header, i.init_pre, i.move_s32pre_stage, i.pre_process, i.move_pre2hdfs, "\n"].join("\n") }.join("\n")
      end

      def postprocess
        # Retrieve the finished files from hdfs, cut out any excess bytes(record length) and compress 
        outfiles.collect{|o| [bash_script_header, o.init_post, o.post_process, o.move_hdfs2post_stage, o.move_post2s3].join("\n") }.join("\n")
      end

      def cleanup_fs
        hcmds = [:hdfs_in_path, :hdfs_out_path].collect{|c| "hadoop fs -rm -r #{send(c)}" }.join("\n")

        cmds = [:pre_path, :pre_stage_path, :post_path, :post_stage_path].collect{|c| "rm -r #{send(c)}" }.join("\n")

        [bash_script_header, no_exit_on_error, hcmds, cmds ].flatten.join("\n")
      end

    end
  end
end
