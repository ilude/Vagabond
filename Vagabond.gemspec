# Ensure we require the local version and not one we might have installed already
$:.push File.expand_path("../lib", __FILE__)
require File.join([File.dirname(__FILE__),'lib','vagabond.rb'])

spec = Gem::Specification.new do |s| 
  s.name = 'Vagabond'
  s.version = Vagabond::VERSION
  s.author = 'Mike Glenn'
  s.email = 'mglenn@ilude.com'
  s.homepage = 'http://www.ilude.com'
  s.platform = Gem::Platform::RUBY
  s.summary = Vagabond::DESCRIPTION
# Add your other files here if you make them
  s.files = %w(
bin/Vagabond
lib/vagabond.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','Vagabond.rdoc']
  s.rdoc_options << '--title' << 'Vagabond' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'Vagabond'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_runtime_dependency('gli')
end
