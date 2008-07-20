module Jabber
  module ComponentFramework
    class Roster
      include Jabber
  
      attr_reader :owner
      def initialize(owner_jid)
        @owner = owner_jid
      end

      def find_or_create(jid)
        ComponentFramework::RosterItem.find_or_create(jid) 
      end
      
      ## XXX Should return nil if it can't find it.
      # Roster should really go to the DB to find the RosterItem and not let roster_item do that
      def find(jid)
        ComponentFramework::RosterItem.find(jid)        
      end
      
      alias_method :[], :find
      
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
          [subscribed, subscribe, pres.to.online_presence(pres.from), item.dequeue_pending_auth_messages].flatten

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
          pres.to.online_presence(pres.from)

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

      def self.all   
        JabberRosterItem.find(:all).collect{ |jri| RosterItem.find(jri.jid) }
      end
        
    end
  end
end