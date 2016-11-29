# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'narp/version'

Gem::Specification.new do |s|
  s.name        = "narp"
  s.version     = Narp::NarpVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Sonny Chee"]
  s.email       = ["Sonny Chee at gmail dot com"]
  s.homepage    = "https://github.com/mercutiomontague/narp"
  s.summary     = %q{Program for declarative processing of flat files}
  s.description = %q{Program for declarative processing of flat files}
  s.license     = 'Nonstandard'

  s.required_rubygems_version = '>= 2.3'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'treetop', '~> 0'
end
