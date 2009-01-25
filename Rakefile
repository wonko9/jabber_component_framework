<<<<<<< HEAD:Rakefile
require 'rake'
require 'yaml'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rcov/rcovtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "jabber_component_framework"
    s.summary = %Q{TODO}
    s.email = "apisoni@geni.com"
    s.homepage = "http://github.com/wonko9/jabber_component_framework"
    s.description = "TODO"
    s.authors = ["Adam Pisoni"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'jabber_component_framework'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Rcov::RcovTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task :default => :rcov
=======
require "#{File.dirname(__FILE__)}/lib/jabber_component_framework"
require 'config/requirements'
require 'config/hoe' # setup Hoe + all gem configuration

Dir['tasks/**/*.rake'].each { |rake| load rake }
>>>>>>> b1e95ecb6a08b358767eea88847e62c138d79a60:Rakefile
