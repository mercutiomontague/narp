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
  class Narp # < OpenStruct
    include Singleton
  	
    @@seq = 0
    @@numeric_types = ['integer', 'float', 'dfloat']
    attr_writer :s3_in_bucket_uri, :s3_out_bucket_uri
    attr_reader :s3_in_bucket_uri, :s3_out_bucket_uri
    attr :infiles, :outfiles, :includes, :joinkeys
    attr :collations, :conditions, :joins, :fields, :output_spec, :collating_sequences
    attr :derived_fields, :domain
    attr :copy
    attr :adapter, :fs, :normalized_nql
  
    def initialize(sys: sys=nil, domain: domain=nil)
      init(sys: sys, domain: domain)
    end
  
  	def init(sys: sys=nil, domain: nil)
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
      @normalized_nql = []
      @s3_in_bucket_uri = 'narp-in-dev'
      @s3_out_bucket_uri = 'narp-out-dev'
      @sys = sys && sys.intern
      require_components
      if @sys == :hive
        @adapter = Hive::Adapter.new
        @fs = Hive::Fs.new
      elsif @sys == :athena
        @adapter = Athena::Adapter.new
      end
  	end

    def require_components
      return unless @sys
      Dir.entries(::File.join( ::File.dirname(__FILE__), 'narp', @sys.to_s)).each {|f|
        next if f =~ /^\.{1,2}/
        require ::File.join('narp', @sys.to_s, f)
      }
    end

    PATH_DEFAULTS = {
                      hdfs_in_path: '/user/hadoop/in',
                      hdfs_out_path: "/user/hadoop/out",
                      pre_path: "~/pre",
                      post_path: "~/post",
                      log_path: "~/log",
                      tmp_path: "/tmp"
                    }


    PATH_DEFAULTS.each {|k, v|
      define_method( k ) {
        ::File.join(v, @domain || '')
      }
    }

    
    def s3_in_bucket_url
      "s3://#{s3_in_bucket_uri}"
    end

    def s3_out_bucket_url
      "s3://#{s3_out_bucket_uri}"
    end

    def s3_in_path
      ::File.join( s3_in_bucket_url, @domain || '')
    end
    
    def s3_out_path
      ::File.join( s3_out_bucket_url, @domain || '')
    end
  
    [:collations, :conditions, :fields ].each {|n|
      eval("
        def #{n}=(other)
          @#{n} = other
        end
        " 
      )
    }
    [:infiles, :outfiles, :includes, :joinkeys, :output_spec ].each {|n|
      eval("
          def #{n}=(other)
            @#{n} << other 
          end
        "
        )
    }

    def parse(input)
  		# Not sure why but I need to add the fake term dummyCommandSonny otherwise the first search term (/collatingsequence) fails to match
      keywords = %w[ /dummyCommandSonny /collatingsequence /condition /copy /fields /include /infile /joinkeys /join /outfile /reformat ]
      lines = input.gsub(/%r{#{keywords.join('|')}/i) {|match| "#{match}"}.split("").reject{|r| r.empty?}
      @normalized_nql << lines.inject( [] ) {|memo, line| 
        memo << parse_one_line(line.strip)
      }
      @normalized_nql.flatten!
      @normalized_nql.compact!
    end
  
    def parse_one_line(input)
      orig_input = input.dup
      input = input.gsub(/--verbose/i, '')
  
      # Occassionally, one or more commands may appear on one line.. so split them
  
      p = SyntaxTree.new('Narp')
      tree = p.parse(input)
      puts tree.inspect if (orig_input != input) # ie. print out the syntax tree if the verbose flag was specified.
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
      tree.to_normalized
    end
  
  
  	def datetime_fields
  		fields.select{|s| s.data_type.value == 'datetime'}
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

    [:ddl, :sql, :cleanup_db].each {|meth|
      define_method( meth ) {
        adapter.send(meth)
      }
    }

    [:preprocess, :postprocess, :cleanup_fs].each {|meth|
      define_method(meth) {
        fs.send(meth)
      }
    }
  
		def processing_steps
			{'Preprocess' => preprocess,  
       'Initialize' => ddl, 
			 'Process' => sql, 
			 'Postprocess' => postprocess, 
       'Cleanup Database' => cleanup_db,
       'Cleanup Filesystem' => cleanup_fs
			}
		end

  end
end

def myapp 
  Narp::Narp.instance
end

