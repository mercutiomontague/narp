#!/usr/bin/env ruby

require 'singleton'
require 'optparse'
require 'ostruct'
require 'treetop'
require 'narp/syntax_tree.rb'
require 'narp/node_extensions.rb'
require 'narp/narp.treetop'
require 'json'
require 'narp/hive/adapter.rb'
require 'narp/hive/fs.rb'

module Narp
  class Narp < OpenStruct
    include Singleton
  	
    @@seq = 0
    @@numeric_types = ['integer', 'float', 'dfloat']
    attr :infiles, :outfiles, :includes, :joinkeys
    attr :collations, :conditions, :joins, :fields, :output_spec, :collating_sequences
    attr :derived_fields, :domain
    attr :copy
    attr :adapter, :fs
  
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
      @adapter = Hive::Adapter.new
      @fs = Hive::Fs.new
  	end

    PATH_DEFAULTS = {s3_in_path: "s3://narp-in-dev",
                      s3_out_path: "s3://narp-out-dev",
                      hdfs_in_path: '/user/hadoop/in',
                      hdfs_out_path: "/user/hadoop/out",
                      pre_stage_path: "~/pre_stage",
                      pre_path: "~/pre",
                      post_stage_path: "~/post_stage",
                      post_path: "~/post",
                      log_path: "~/log" 
                    }


    [:s3_in_path, :s3_out_path, :hdfs_in_path, :hdfs_out_path, :pre_stage_path, :pre_path, :post_path, :post_stage_path].each {|n|
      define_method( n ) {
        ::File.join(PATH_DEFAULTS[n], @domain || '')
      }
    }
  
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
  
    def declared_fields
      [fields, derived_fields].flatten.compact
    end

    def lhs_tables
      infiles.lhs_tables
    end

    def rhs_tables
      infiles.rhs_tables
    end

    [:ddl, :hql, :cleanup_db].each {|meth|
      define_method( meth ) {
        adapter.send(meth)
      }
    }

    [:preprocess, :postprocess, :cleanup_fs].each {|meth|
      define_method(meth) {
        fs.send(meth)
      }
    }
    
    def analyze_sources
      JSON.generate( infiles.select{|i| i.analyze}.inject({}){ |memo, i| 
          memo[i.original_name] = i.analyze
        } 
      )
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

