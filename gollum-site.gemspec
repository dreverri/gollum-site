# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gollum-site/version"

Gem::Specification.new do |s|
  s.name        = "gollum-site"
  s.version     = Gollum::Site::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Daniel Reverri"]
  s.email       = ["dan@basho.com"]
  s.homepage    = "http://rubygems.org/gems/gollum-site"
  s.summary     = %q{Static site generator for Gollum Wikis}
  s.description = %q{Generate a static site for Gollum Wikis}

  s.rubyforge_project = "gollum-site"

  s.add_dependency('gollum', '1.4.3')
  s.add_dependency('liquid', '>= 2.2.2')
  s.add_dependency('mixlib-log', '>= 1.1.0')
  s.add_dependency('directory_watcher')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
