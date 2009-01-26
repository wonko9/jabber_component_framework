module Jabber::ComponentFramework::PresenceAdapters
  class AbstractAdapter
    class NotImplementedError < StandardError; end
    
    include Jabber
    attr_accessor :presence_data
    attr_reader :jid
    def initialize(jid,presence_data=nil)
      @jid                          = jid
      @presence_data                = presence_data
      @presence_data[:resources]    ||= {}
      @presence_data[:availability] ||= :unknown
    end
    
    def resources
      presence_data[:resources]
    end    
    
    def resources=(resources)
      presence_data[:resources] = resources      
    end
    
    def availability
      presence_data[:availability]
    end
    
    def availability=(avail)
      presence_data[:availability] = avail      
    end
    
    def save
      raise NotImplementedError.new("save must be implemented in you subclass")
    end

    def self.find(jid)
      raise NotImplementedError.new("self.find must be implemented in you subclass")
    end

    def self.create(jid,presence_data=nil)
      raise NotImplementedError.new("self.create must be implemented in you subclass")
    end    
  end
end