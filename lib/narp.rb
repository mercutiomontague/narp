#!/usr/bin/env ruby

require 'singleton'
require 'optparse'
require 'ostruct'
require 'treetop'
require 'narp/syntax_tree.rb'
require 'narp/node_extensions.rb'
require 'narp/narp.treetop'
require 'json'

module Narp
  class Narp < OpenStruct
    include Singleton
  	
    @@seq = 0
    @@numeric_types = ['integer', 'float', 'dfloat']
    attr :domain
    attr :s3_in_path, :s3_out_path, :hdfs_out_path, :hdfs_in_path 
    attr :pre_stage_path, :pre_path, :post_stage_path, :post_path
    attr :infiles, :outfiles, :includes, :joinkeys
    attr :collations, :conditions, :joins, :fields, :output_spec, :collating_sequences
    attr :derived_fields
    attr :output_spec
  
    def initialize
      init
      define_methods
    end
  
  	def init(domain = nil)
      @domain = domain
      @@seq = 0
      @fields = []
      @derived_fields = []
      @collations = []
      @conditions = []
      @collating_sequences = []
      @joins = []
      @infiles = InfileList.new
      @outfiles = OutfileList.new
      @includes = IncludesList.new
      @joinkeys = JoinKeysList.new
      @output_spec = OutputSpec.new
      @s3_in_path = "s3://narp-in-dev"
      @s3_out_path = "s3://narp-out-dev"
      @hdfs_in_path = '/user/hadoop/in'
      @hdfs_out_path = "/user/hadoop/out"
      @pre_stage_path = "~/pre_stage"
      @pre_path = "~/pre"
      @post_stage_path = "~/post_stage"
      @post_path = "~/post"
      @output_spec = OutputSpec.new
  	end
  
    def parse(input)
  		# Not sure why but I need to add the fake term dummyCommandSonny otherwise the first search term (/collatingsequence) fails to match
      keywords = %w[ /dummyCommandSonny /collatingsequence /condition /copy /fields /include /infile /joinkeys /join /outfile /reformat ]
      lines = input.gsub(/%r{#{keywords.join('|')}/i) {|match| "#{match}"}.split("").reject{|r| r.empty?}
      lines.each {|line| parse_one_line(line.strip)}
    end
  
    def parse_one_line(input)
      orig_input = input.dup
      input = input.gsub(/--verbose/i, '')
  
      # Occassionally, one or more commands may appear on one line.. so split them
  
      p = SyntaxTree.new('Narp')
      tree = p.parse(input)
      puts tree.inspect if (orig_input != input)
      case tree.class.to_s
        when 'Narp::Domain'
          @domain = tree.name
        when 'Narp::Infile'
          infiles << tree
        when 'Narp::Outfile'
          outfiles << tree
        when 'Narp::Fields'
          tree.fields.each {|e| fields << e}
        when 'Narp::Condition'
          conditions << tree
        when 'Narp::Include'
          includes << tree
        when 'Narp::Join'
          joins << tree
        when 'Narp::JoinKeys'
          joinkeys << tree
        when 'Narp::Reformat'
          output_spec << tree
        when 'Narp::Copy'
          @copy = true
        when 'Narp::CollatingSequence'
          collating_sequences << tree
        when 'Narp::DerivedField'
          derived_fields << tree
      end
    end
  
    def define_methods 
      [:collations, :conditions, :fields ].each {|n|
        instance_eval("
          def #{n}=(other)
            @#{n} = other
          end
        "
        )
      }
      [:infiles, :outfiles, :includes, :joinkeys, :output_spec ].each {|n|
        instance_eval("
          def #{n}=(other)
            @#{n} << other 
          end
        "
        )
      }
    end 
  
  	def numeric_fields
  		fields.select{|s| @@numeric_types.detect{|z| s.data_type.value == z}}
  	end
  
  	def character_fields
  		fields.select{|s| s.data_type.value == 'character' }
  	end
  	
    def next_sequence
      @@seq += 1
    end
  
    def join_type
      raise ArgumentError.new("I don't know how to handle multiple joins clauses") if joins.size > 1
      case 
        when joinkeys.empty?
          nil
        when joins.size == 0
          'INNER JOIN'
        else
          joins.first.value.upcase
      end
    end
  
    def get(name, type)
      case type.to_s
        when 'Narp::NumericFieldName'
          numeric_fields.detect{|d| d.name == name}
        when 'Narp::CharacterFieldName'
          character_fields.detect{|d| d.name == name}
        when 'Narp::FieldName'
          fields.detect{|d| d.name == name}
        when 'Narp::DerivedFieldName'
          derived_fields.detect{|d| d.name == name}
        when 'Narp::ConditionName'
          conditions.detect{|d| d.name == name}
      end
    end
  
  	def first_explicit_field_seperator
  		infiles.collect{|i| i._field_seperator}.compact.first
  	end

    def placeholder
      '__sonny_placeholder__'
    end
  
    def schema
      'stage'
    end
  
    def column_name(num)
      "col_#{num}"
    end

    def all_fields
      [fields, derived_fields].flatten.compact
    end
  
  	def ddl
      ["CREATE DATABASE #{domain};", 
       use_db, 
  		[infiles.collect{|i| i.ddl}, outfiles.collect{|o| o.ddl}]].flatten.join("\n\n")
  	end
  
    # Generate the hql for the lhs or rhs tables. Tables on each side are unioned.
    def table_clause(tables)
      return nil unless tables.any?
      "(\n" << tables.collect{|i| 
        "SELECT\n" << ("\t" << 
           fields.collect{|f| f.to_column_expression}.join("\n\t, ")).sql_justify_on_alias << 
        "\nFROM\n\t#{i.hive_name}"
      }.join("\nUNION ALL\n") << "\n) #{tables == infiles.lhs_tables ? :lhs : :rhs}"
    end
  
    def src_clause
      [table_clause(infiles.lhs_tables), 
       join_type, 
       table_clause(infiles.rhs_tables), 
       joinkeys.predicate_hql
      ].flatten.compact.join("\n")
    end
  
    def src_sql
      "SELECT\n" <<
        ("\t" << output_spec.src_column_expressions.join("\n\t, ")).sql_justify_on_alias << "\n" << 
      "FROM\n" << src_clause.myindent << "\n"
    end

    def use_db
      "USE #{domain};"
    end
  
    def hql
      use_db << "\n" <<
      "FROM (\n#{src_sql.myindent}\n)src\n" << 
      outfiles.collect{|o| o.populate_hql }.join("\n\n") << "\n;"
    end

    def preprocess
      # Unzip, Extract the necessary lines (:%s/skipto, stopafter) and finally put the files where HIVE can find them.
      infiles.collect{|i| ["#!/bin/bash\n", i.init_pre, i.move_s32pre_stage, i.pre_process, i.move_pre2hdfs, "\n"].join("\n") }.join("\n")
    end

    def analyze_sources
      JSON.generate( infiles.select{|i| i.analyze}.inject({}){ |memo, i| 
          memo[i.original_name] = i.analyze
        } 
      )
    end
  
    def postprocess
      # Retrieve the finished files from hdfs, cut out any excess bytes(record length) and compress 
      outfiles.collect{|o| ["#!/bin/bash", o.move_hdfs2post_stage, o.post_process, o.move_post2s3].join("\n") }.join("\n")
    end

    def cleanup_db
      [use_db, [infiles, outfiles].flatten.collect{|o| o.drop_ddl}, "DROP DATABASE #{domain};"].flatten.join("\n")
    end

    def cleanup_fs
      [infiles, outfiles].flatten.collect{|o| o.cleanup}.join("\n")
    end

		def generate_json_output
			::JSON.pretty_generate( {:preprocess => preprocess, :ddl => ddl, 
										        		:hql => hql, 
                                :cleanup_db => cleanup_db,
										        		:postprocess => postprocess, 
                                :cleanup_fs => cleanup_fs,
                                :s3_input_mapping => infiles.s3_mappings,
										        		:s3_output_mapping => outfiles.s3_mappings
										        	 }
										        ) 
		end
  end
end

def myapp 
  Narp::Narp.instance
end

# def parse_options
#   options = OpenStruct.new
#   opt_parser = OptionParser.new do |opts|
#     opts.banner = "Usage: narp.rb [options] narp_program_definition"
#     mess =  "\nIf the program definition is provided on the command line: \n"
# 		mess += "1) it must be enclosed in double quotes.\n"
# 		mess += "2) double quotes and $ within the program definition must be escaped.\n\n"
# 		mess += "Option:\n"
# 
# 		opts.separator mess
# 
#     opts.on('--domain NAMESPACE', 'Specify the namespace to group this program within') do |n|
#       options.domain = n
#     end
# 
#     opts.on('--file PROGRAM_FILE', 'Read the Narp program definition from PROGRAM_FILE') do |q|
#       options.program_file = q
#     end
# 
#   end
#   opt_parser.parse!(ARGV)
#   options
# end
# 
# def read_program_file(opt)
#   return nil unless opt.program_file
#   File.open(opt.program_file, 'r').readlines.join("\n")
# end
# 
# if $0 == __FILE__
#   opts = parse_options
#   myapp.init(opts.domain)
#   program = read_program_file(opts) || ARGV.join(' ')
#   myapp.parse(program)
#   puts myapp.generate_json_output
# end
