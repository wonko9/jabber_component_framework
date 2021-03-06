module Jabber
  module ComponentFramework
    class Roster
      include Jabber

      attr_reader :owner
      attr_accessor :presence_adapter, :roster_adapter, :auto_subscribe
      def initialize(owner_jid,options={})
        @owner                = owner_jid
        @auto_subscribe       = options[:auto_subscribe]
        self.roster_adapter   = options[:roster_adapter] || Jabber::ComponentFramework::RosterAdapters::Noop
        self.presence_adapter = options[:presence_adapter] || Jabber::ComponentFramework::PresenceAdapters::Noop
      end

      def find_or_create(jid,avail = :unsubscribed)
        jid = Jabber::JID.return_or_new(jid)
        find(jid) || create(jid,avail)
      end

      def find(jid)
        jid = Jabber::JID.return_or_new(jid)

        persistent_roster_item = roster_adapter.find(jid)
        return false unless persistent_roster_item
        presence = presence_adapter.find(jid)

        if not presence
          # There was no record of their presence in th presence cache so we create an :unknown one
          presence_options = {:availability => :subscribed}
          presence_options[:availability] = :unsubscribed unless persistent_roster_item.subscribed
          presence = presence_adapter.create(jid,presence_options)
        end
        jid_presence = JIDPresence.new(jid,presence)
        ComponentFramework::RosterItem.new(jid,jid_presence,persistent_roster_item)
      end
      alias_method :[], :find

      def create(jid,avail = :unsubscribed)
        presence = presence_adapter.find(jid) || presence_adapter.create(jid)
        jid_presence              = JIDPresence.new(jid,presence)
        jid_presence.availability = avail
        roster_db_item            = roster_adapter.create(jid)
        ComponentFramework::RosterItem.new(jid,jid_presence,roster_db_item)
      end

      # Handle received <tt><presence/></tt> stanzas,
      # XXX Not sure if this should go in roster_item or not
      def handle_presence(pres)
        item = self[pres.from]
        item ||= create(pres.from) if auto_subscribe
        return unless item

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