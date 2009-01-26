module Jabber::ComponentFramework::PresenceAdapters
  class Memory < AbstractAdapter
    include Jabber

    def save                            
      if self.class.presence_cache[jid.bare.to_s]
        self.class.presence_cache[jid.bare.to_s].merge!(presence_data)
      else
        self.class.presence_cache[jid.bare.to_s] = presence_data
      end
    end

    def self.find(jid)
      new(jid, presence_cache[jid.bare.to_s]) if presence_cache[jid.bare.to_s]
    end

    def self.create(jid,presence_data={})
      presence_cache[jid.bare.to_s] ||= {:availability => nil, :resources => {}}
      new(jid, presence_cache[jid.bare.to_s].merge!(presence_data))
    end

    def self.clear
      @presence_cache = {}
    end

    # private

    def self.presence_cache
      @presence_cache || clear
    end
  end
end