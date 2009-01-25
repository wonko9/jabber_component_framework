module Jabber::ComponentFramework::PresenceAdapters
  class Memory < AbstractAdapter
    include Jabber
    
    def save
      self.class.presence_cache[jid.bare.to_s] = presence_data      
    end

    def self.find(jid)
      new(jid, presence_cache[jid.bare.to_s]) if presence_cache[jid.bare.to_s]
    end

    def self.create(jid,presence_data=nil)
      new(jid, presence_cache[jid.bare.to_s] = presence_data)
    end
    
    def self.clear
      @presence_cache = Hash.new({:availablity => nil, :resources => {}})
      
    end
    
    private

    def self.presence_cache
      @presence_cache || clear
    end
  end
end