#!/usr/bin/env ruby
#
require 'singleton'

module Narp
  class ParseIssue 
    include Singleton

    def message=(other)
      @message = other
    end

    def message
      @message
    end
  end
end
  
def parse_issue
  Narp::ParseIssue.instance
end
