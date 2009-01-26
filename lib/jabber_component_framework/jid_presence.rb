module Jabber
  module ComponentFramework
    class JIDPresence

      attr_reader :jid, :presence_item
      def initialize(jid,presence_item=nil)
        @jid = Jabber::JID.return_or_new(jid)
        @presence_item = presence_item || adapter.new(jid)        
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

      def presence_data
        {:availability => availability, :resources => resources}      
      end
      def online!
        self.availability = :online
      end

      def offline!
        self.availability = :offline
      end

      def availability
        return presence_item.availability if presence_item.availability
        return :online if resources.keys.any?
        return :offline
      end

      def availability=(avail)
        set_availablity_for_resource(avail,jid.resource.to_s)
        presence_item.save
      end

      def self.adapter=(adapter)
        @adapter=adapter
      end

      def self.adapter
        @adapter ||= Jabber::ComponentFramework::PresenceAdapters::Memory
      end

      def adapter
        self.class.adapter
      end
      
      private
            
      def resources
        presence_item.resources ||= {}
      end

      def set_availablity_for_resource(avail,resource)
        case avail
        when :online
          mark_resource_online(resource)
        when :offline
          mark_resource_offline(resource)
        else
          presence_item.resources = {}
          presence_item.availability = avail
        end      
      end    

      def mark_resource_online(resource=nil)
        if resource
          resources[resource.to_s] = true
        elsif self.resources.keys.empty?
          resources[''] = true
        end
        presence_item.availability = :online
      end

      def mark_resource_offline(resource=nil)
        if resource
          resources.delete('') if resource.any? and resources.has_key?('')
          resources.delete(resource.to_s)
        else
          presence_item.resources = {}
        end
        presence_item.availability = :offline if resources.keys.empty?
      end
      
    end
  end
end
