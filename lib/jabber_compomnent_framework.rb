$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.join(File.dirname(__FILE__),"jabber_component_framework"))

require 'rubygems'
require 'pp'
require 'forwardable'

# require xmpp4r libs
require 'xmpp4r'
require 'xmpp4r/roster'
require 'xmpp4r/discovery'
require 'xmpp4r/vcard'
require 'xmpp4r/version'
require 'xmpp4r/feature_negotiation'

# require jabber_component_framework libs
require 'queue_proxy'
require 'jid_extensions'
require 'jid_presence'
require 'component_jid'
require 'roster'
require 'roster_item'
require 'controller'

# ===========================
# = XXX FIXME This is dirty =
# ===========================
module Jabber::ComponentFramework
  
  def self.queue_proxy=(queue_proxy)
    MessageQueue.proxy=queue_proxy
  end
  
  class MessageQueue
    def self.proxy
      @queue_proxy ||= QueueProxy.new      
    end

    def self.proxy=(p)
      @queue_proxy = p
    end
  end
  
  class PresenceStore
    ### This is workfeed stuff!!!
    require "#{File.dirname(__FILE__)}/../../../../config/initializers/memcache" unless defined?(CACHE)
    require 'memcache'
    
    def self.proxy
      # Cache is either just the Memcache client or the Memcache mock
      CACHE
    end
  end

  class RosterItemStore
    require "#{File.dirname(__FILE__)}/../../../../app/models/jabber_roster_item"
    unless ActiveRecord::Base.connected?
      dbconfig = YAML::load(File.open("#{File.dirname(__FILE__)}/../../../../config/database.yml"))  
      ActiveRecord::Base.allow_concurrency = true
      ActiveRecord::Base.establish_connection(dbconfig[RAILS_ENV])
      ActiveRecord::Base.connection
    end

    def self.proxy
      JabberRosterItem
    end
  end

end