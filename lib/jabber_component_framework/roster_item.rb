module Jabber
  module ComponentFramework
    class RosterItem
      include Jabber
      extend Forwardable

      attr_reader :jid, :persistent_roster_item, :presence
      def initialize(jid, presence, persistent_roster_item=nil)
        @jid = Jabber::JID.return_or_new(jid)
        @presence = presence
        @persistent_roster_item = persistent_roster_item
      end

      def_delegators :jid, :strip, :bare, :hash, :node, :resource, :domain, :stripped?

      def enqueue_deferred_messages(message)
        persistent_roster_item.enqueue_deferred_messages([message])
      end                  

      def dequeue_deferred_messages
        persistent_roster_item.dequeue_deferred_messages || []
      end

      def_delegators :presence, :available?, :online?, :offline?
      
      def online!
        subscribe! if not subscribed?
        presence.online!        
      end
      
      def offline!
        subscribe! if not subscribed?
        presence.offline!                
      end

      def subscribed?
        # See if the presence cache knows whether they are subscribed
        return true if presence.subscribed?

        # If we don't know they're presence AND they're not marked as unsubscribed we have to check the DB
        if persistent_roster_item.subscribed
          # should do a probe here.  This means we KNOW we're subscribed,
          # but we didn't know whether they were on or offline
          presence.availability = :subscribed
          return true

          # We know about them, they are unsubscribed, but there was no cache entry.
          # Lets create a cache entry and mark it as unsubscribed
        else
          presence.availability = :unsubscribed
          return false
        end
      end

      def subscribe!
        persistent_roster_item.subscribed = true
        persistent_roster_item.save
        presence.availability = :unknown unless presence.online? or presence.offline?
      end

      def unsubscribe!
        persistent_roster_item.subscribed = false
        persistent_roster_item.save
        self.presence.availability = :unsubscribed
      end

    end
  end
end # end Roster::Item
