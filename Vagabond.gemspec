# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','Vagabond_version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'Vagabond'
  s.version = Vagabond::VERSION
  s.author = 'Mike Glenn'
  s.email = 'mglenn@ilude.com'
  s.homepage = 'http://www.ilude.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Manage Virtualbox virtual machines from ISO images to running boxes'
# Add your other files here if you make them
  s.files = %w(
bin/Vagabond
lib/Vagabond_version.rb
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
