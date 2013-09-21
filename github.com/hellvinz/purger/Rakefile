#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rake/testtask"
require "yard"

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['spec/*_spec.rb']
  t.verbose = true
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
end
