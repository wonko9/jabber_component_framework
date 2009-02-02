module Jabber::ComponentFramework::PresenceAdapters
  class Noop < AbstractAdapter
    include Jabber

    def save
      true
    end

    def self.find(jid)
      new(jid, {:availability => :online, :resources => {}})
    end

    def self.create(jid,presence_data={})
      new(jid, {:availability => :online, :resources => {}}.merge!(presence_data))
    end

  end
end