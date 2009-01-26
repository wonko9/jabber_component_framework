# ==============================
# = Default Roster Item Stores =
# ==============================
module Jabber::ComponentFramework::RosterAdapters
  class Memory < AbstractAdapter
    include Jabber

    def self.find(jid)
      new(jid, roster_item_store[jid.bare.to_s]) if roster_item_store[jid.bare.to_s]
    end

    def self.create(jid,value={})
      roster_item_store[jid.bare.to_s] = value
      new(jid, roster_item_store[jid.bare.to_s])
    end

    def self.clear
      @roster_item_store = {}
      @deferred_messages = Hash.new([])
    end

    def save
      if roster_item_store[jid.bare.to_s]
        roster_item_store[jid.bare.to_s].merge!(options)
      else
        roster_item_store[jid.bare.to_s] = options
      end
    end


    attr_accessor :jid, :options
    def initialize(jid,options={})
      @jid     = jid
      @options = options
    end

    def enqueue_deferred_messages(messages)
      deferred_messages[jid.bare.to_s] += [messages].flatten
    end

    def dequeue_deferred_messages
      deferred_messages.delete(jid.bare.to_s)
    end

    def self.roster_item_store
      @roster_item_store ||= {}
    end

    def roster_item_store
      self.class.roster_item_store
    end

    def self.deferred_messages
      @deferred_messages ||= Hash.new([])
    end

    def deferred_messages
      self.class.deferred_messages
    end

  end  # end MemoryStore
end