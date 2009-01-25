module Jabber::ComponentFramework::PresenceAdapters
  class AbstractAdapter
    class NotImplementedError < StandardError; end
    
    include Jabber
    attr_accessor :availability, :resources
    attr_reader :jid
    def initialize(jid,presence_data=nil)
      @jid             = jid
      presence_data  ||= {}
      @resources       = presence_data[:resources] || {}
      @availability    = presence_data[:availability] || :unknown
    end
    
    def presence_data
      {:resources => resources, :availability => availability}      
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