module Jabber
  module ComponentFramework
    class Roster
      include Jabber

      attr_reader :owner
      attr_accessor :presence_adapter, :roster_adapter
      def initialize(owner_jid,options={})
        @owner                = owner_jid
        self.roster_adapter   = options[:roster_adapter] || Jabber::ComponentFramework::RosterAdapters::Memory
        self.presence_adapter = options[:presence_adapter] || Jabber::ComponentFramework::PresenceAdapters::Memory
      end

      def find_or_create(jid,avail = :unsubscribed)
        jid = Jabber::JID.return_or_new(jid)
        roster_item = find(jid)
        roster_item || create(jid,avail)
      end

      def find(jid)
        jid = Jabber::JID.return_or_new(jid)

        persistent_roster_item = roster_adapter.find(jid)
        return false unless persistent_roster_item
        jid_presence = JIDPresence.new(jid,presence_adapter.find(jid))

        if not jid_presence
          # There was no record of their presence in th presence cache so we create an :unknown one
          jid_presence = JIDPresence.new(jid)

          # We mark the presence as :unsubscribed instead of :unknown if they are really not subscribed
          jid_presence.availability = :unsubscribed if not persistent_roster_item.subscribed?
        end
        ComponentFramework::RosterItem.new(jid,jid_presence,persistent_roster_item)
      end
      alias_method :[], :find

      def create(jid,avail = :unsubscribed)
        jid_presence              = JIDPresence.new(jid)
        jid_presence.availability = avail
        roster_db_item            = roster_adapter.create(jid)
        ComponentFramework::RosterItem.new(jid,jid_presence,roster_db_item)
      end      

      # Handle received <tt><presence/></tt> stanzas,
      # XXX Not sure if this should go in roster_item or not
      def handle_presence(pres)
        item = self[pres.from]
        return false unless item
        case pres.type
        when :subscribed
          # XXX I wanted to pub the functionality currently in subscribed into this subscribe section
          # but some clients (I'm talking to you Adium) never respond with a subscribed presence
          # subscribe!
          nil

        when :subscribe
          # XXX Wish we could call subscribe against the roster_item
          item.subscribe!
          item.online!

          # if a user has our bot in their roster but without a subscription
          # type of "both" then they will never probe for our presence when they log in.
          # So we must send a user a subscribe presence when they ask us to subscribe
          # from: http://www.xmpp.org/extensions/xep-0162.html
          subscribed = pres.answer
          subscribed.type = :subscribed
          subscribe = pres.answer
          subscribe.from = subscribe.from.bare
          [subscribed, subscribe, pres.to.online_presence(pres.from), item.dequeue_deferred_messages].flatten

        when :unsubscribe
          item.unsubscribe!

          unsubscribed = pres.answer
          unsubscribed.type = :unsubscribed
          unsubscribed

        when :unsubscribed
          # ?
          return nil

        when nil, :online
          item.online!

          # Try sending back our online presence when people tell us their online
          pres.to.online_presence(pres.from) if pres.to

        when :unavailable: :unavailable
          item.offline!
          return nil

        when :probe
          # What's weird about having this here, is usually they are probing for the components presence.
          # Yet here we are in the roster as if our component were in our own roster. Maybe thats ok.
          item.online!
          pres.to.online_presence(pres.from)

        when :error
          if [404,503].include?(pres.error.code)
            item.offline!
          end
          return nil
        end
        
      end
      
    end
  end
end