$:.unshift(File.join(File.dirname(__FILE__),"jabber_component_framework"))
$:.unshift(File.dirname(__FILE__))

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
require 'jid_extensions'
require 'jid_presence'
require 'component_jid'
require 'roster'
require 'roster_item'
require 'controller'
require 'roster_adapters/abstract_adapter'
require 'roster_adapters/memory'
require 'presence_adapters/abstract_adapter'
require 'presence_adapters/memory'



# ===========================
# = XXX FIXME This is dirty =
# ===========================
# module Jabber::ComponentFramework
#   
#   def self.queue_proxy=(queue_proxy)
#     MessageQueue.proxy=queue_proxy
#   end
#   
#   class MessageQueue
#     def self.proxy
#       if defined?(QUEUE)
#         @queue_proxy ||= QUEUE
#       else
#         @queue_proxy ||= QueueProxy.new      
#       end
#     end
# 
#     def self.proxy=(p)
#       @queue_proxy = p
#     end
#   end
#   
#   class PresenceCache
#     def self.proxy
#       CACHE
#     end
#   end
# 
#   require "#{File.dirname(__FILE__)}/../../../../app/models/jabber_roster_item"
#   class RosterItemCache
#     def self.proxy
#       JabberRosterItem
#     end
#   end
# 
# end