# ==============================
# = Default Roster Item Stores =
# ==============================
module Jabber::ComponentFramework::RosterAdapters
  class AbstractAdapter
    include Jabber

    attr_accessor :jid, :options
    def initialize(jid,options={})
      @jid     = jid
      @options = options
    end

    def subscribed
      options[:subscribed]
    end

    def subscribed=(sub)
      options[:subscribed] = sub
    end

  end  # end MemoryStore
end