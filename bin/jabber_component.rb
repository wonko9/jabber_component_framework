#!/usr/bin/env ruby

$:.unshift("#{File.dirname(__FILE__)}/../lib/")

RAILS_ENV = ENV["RAILS_ENV"] || "development" unless defined?(RAILS_ENV)

require 'pp'                     
require 'rubygems'
require 'yaml'
require 'i_can_daemonize'                           
require 'jabber_component_framework'


class JabberComponentRunner
  include ICanDaemonize

  before do
    config = YAML::load(File.open("#{File.dirname(__FILE__)}/../config/jabber_component.yml"))  
    @controller = Jabber::ComponentFramework::Controller.new(config[RAILS_ENV])
  end
  
  daemonize() do
    @controller.delivery_thread.join
  end
end