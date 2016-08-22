$LOAD_PATH.unshift 'lib'
require 'related/version'

Gem::Specification.new do |s|
  s.name        = 'related'
  s.version     = Related::Version
  s.summary     = 'Related is a Redis-backed high performance distributed graph database.'
  s.description = 'Related is a Redis-backed high performance distributed graph database.'
  s.license     = 'MIT'

  s.author      = 'Niklas Holmgren'
  s.email       = 'niklas@sutajio.se'
  s.homepage    = 'http://github.com/sutajio/related/'

  s.require_path  = 'lib'

  s.files             = %w( README.md Rakefile LICENSE CHANGELOG )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")
  s.files            += Dir.glob("tasks/**/*")

  s.extra_rdoc_files  = [ "LICENSE", "README.md" ]
  s.rdoc_options      = ["--charset=UTF-8"]

  s.add_dependency('redis',  '> 2.0.0')
  s.add_dependency('redis-namespace',  '> 0.8.0')
  s.add_dependency('activemodel')
end
