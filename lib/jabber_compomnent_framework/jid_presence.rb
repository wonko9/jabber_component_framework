module Jabber
  module ComponentFramework
    class JIDPresence

      def self.find(jid)           
        jid = Jabber::JID.return_or_new(jid)
        cache = PresenceStore.proxy.get("im_presence_#{jid.bare}")
        new(jid,cache) if cache
      end
      
      attr_reader :jid

      def initialize(jid,cache=nil)
        @jid = Jabber::JID.return_or_new(jid)

        if cache
          if cache.is_a?(Array)
            @presence_cache = cache
          else
            self.availability = cache            
          end
        else
          self.availability = :unknown          
        end
      end
            
      def available?
        online?
      end

      def online?
        availability == :online
      end
      
      def offline?
        availability == :offline
      end
      
      def subscribed?
        return true if online? or offline? or availability == :subscribed
      end
      
      def availability
        presence_cache[0]
      end
      
      def online!
        self.availability = :online
      end
      
      def offline!
        self.availability = :offline
      end
      
      def availability=(avail)          
        # puts "ADAMDEBUG: AVAIL got #{avail.inspect}"
        # prev_cache = presence_cache.dup
        presence_cache[1] = {} unless presence_cache[1].is_a?(Hash)

        if avail == :online
          presence_cache[1][jid.resource.to_s] = true
          presence_cache[0] = avail
        elsif avail == :offline     
          if jid.resource
            presence_cache[1].delete(jid.resource.to_s) if presence_cache[1]
          else
            presence_cache[1] = {}
          end
          presence_cache[0] = :offline if presence_cache[1].keys.empty?
        else
          presence_cache[1] = {}
          presence_cache[0] = avail        
        end
        pp "PRESENCE CACHE CHANGED #{jid} TO", presence_cache
        PresenceStore.proxy.set("im_presence_#{jid.bare}",presence_cache)
      end
      
      def presence_cache
        @presence_cache ||= [nil,{},{}]
      end

    end
  end
end
