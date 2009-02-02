# ==============================
# = Default Roster Item Stores =
# ==============================
module Jabber::ComponentFramework::RosterAdapters
  class Noop < AbstractAdapter
    include Jabber

    def self.find(jid)
      new(jid, {:subscribed => true})
    end

    def self.create(jid,value={})
      new(jid, {:subscribed => true}.merge(value))
    end

    def save
      true
    end

    attr_accessor :jid, :options
    def initialize(jid,options={})
      @jid     = jid
      @options = options
    end

    def enqueue_deferred_messages(messages)
      true
    end

    def dequeue_deferred_messages
      true
    end

  end  # end NoopAdapter
end