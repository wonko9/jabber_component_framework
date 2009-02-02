module Jabber::ComponentFramework::PresenceAdapters
  class Memcache < AbstractAdapter
    include Jabber
    
    def self.client=(client)
      @client = client
    end
    
    def self.client
      @client      
    end

    def save
      client.set(cache_key,presence_data)
      self
    end

    def self.find(jid)
      cache = client.get(cache_key)
      new(jid, cache) if cache
    end

    def self.create(jid,presence_data={})
      presence_cache[jid.bare.to_s] ||= {:availability => nil, :resources => {}}
      new(jid, presence_cache[jid.bare.to_s].merge!(presence_data)).save
    end
    
    def cache_key
      "jcf:pres:#{jid.bare.to_s}"
    end

  end
end