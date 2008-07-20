module Jabber
  module ComponentFramework
    class RosterItem
      include Jabber
      extend Forwardable
      
      def initialize(jid, presence, persistent_roster_item=nil)
        @jid = Jabber::JID.return_or_new(jid)
        @presence = presence
        @persistent_roster_item = persistent_roster_item
      end
      
      attr_reader :jid
      def_delegators :jid, :strip, :bare, :hash, :node, :resource, :domain, :stripped?
      
      def add_pending_auth_message(message)
        pending_messages = PresenceStore.proxy.get("im_pending_#{strip}")
        pending_messages = [] unless pending_messages.is_a?(Array)
        pending_messages << message
        PresenceStore.proxy.set("im_pending_#{strip}", pending_messages)
      end
      
      def dequeue_pending_auth_messages
        pending_messages = PresenceStore.proxy.get("im_pending_#{strip}")
        if pending_messages
          PresenceStore.proxy.delete("im_pending_#{strip}")
          pending_messages
        else 
          []
        end
      end
            
      def presence
        @presence ||= JIDPresence.find(jid)
      end
      
      def_delegators :presence, :online!, :offline!, :available?, :online?, :offline?
      
      def subscribed?
        # See if the presence cache knows whether they are subscribed
        return true if presence.subscribed?

        # If we don't know they're presence AND they're not marked as unsubscribed we have to check the DB
        if persistent_roster_item.subscribed?
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
        persistent_roster_item.subscribe!
        presence.availability = :unknown unless presence.online? or presence.offline?
      end
            
      def unsubscribe!          
        persistent_roster_item.unsubscribe!
        self.presence.availability = :unsubscribed
      end

      def persistent_roster_item
        @persistent_roster_item ||= self.class.persistent_roster_item(self.jid)
      end

      def self.find(jid)
        jid = Jabber::JID.return_or_new(jid)
        jid_presence = JIDPresence.find(jid)
        roster_db_item = nil

        if not jid_presence
          roster_db_item = persistent_roster_item(jid)
          return false unless roster_db_item

          # There was no record of their presence in th presence cache so we create an :unknown one
          jid_presence = JIDPresence.new(jid)
          
          # We mark the presence as :unsubscribed instead of :unknown if they are really not subscribed
          jid_presence.availability = :unsubscribed if not roster_db_item.subscribed?
        end

        new(jid,jid_presence,roster_db_item)
      end
      
      def self.find_or_create(jid,avail = :unsubscribed)
        jid = Jabber::JID.return_or_new(jid)
        roster_item = find(jid)
        if not roster_item
          jid_presence = JIDPresence.new(jid,avail)
          roster_db_item = RosterItemStore.proxy.create(:jid => jid.bare.to_s)
          roster_item = ComponentFramework::RosterItem.new(jid,jid_presence,roster_db_item)
        end
        roster_item
      end

      def self.persistent_roster_item(jid)
        jid = Jabber::JID.return_or_new(jid)
        RosterItemStore.proxy.find_by_jid(jid.strip.to_s)
      end
            
    end # end Roster::Item
  end
end

