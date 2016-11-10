# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'guard/aws-s3/version'

Gem::Specification.new do |s|
  s.name        = "guard-aws-s3"
  s.version     = Guard::AwsS3Version::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Sonny Chee"]
  s.email       = ["Sonny Chee at gmail dot com"]
  s.homepage    = "http://github.com/guard/guard-aws-s3"
  s.summary     = %q{Guard plugin for syncing files with AWS S3}
  s.description = %q{Guard plugin for syncing files with AWS S3 using AWS-SDK v2.}
  s.license     = 'MIT'

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project         = "guard-aws-s3"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'aws-sdk', '~> 2.0'
  s.add_dependency 'guard', '~> 2.0'
end
