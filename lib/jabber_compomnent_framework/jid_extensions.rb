module Jabber
  class JID

    def self.return_or_new(node = "", domain = nil, resource = nil)
      return node if node.is_a?(Jabber::JID)
      new(node,domain,resource)
    end
    
    def jid
      to_s
    end

    PRESENCE_OPTIONS = [:to, :type, :show, :status, :priority, :id]
    def new_presence(options={})
      pres = Presence.new
      if options[:bare]
        pres.from = self.bare
      else
        pres.from = self
      end
      PRESENCE_OPTIONS.each do |pres_option|
        pres.send("#{pres_option}=",options[pres_option]) if options.has_key?(pres_option)
      end
      pres
    end      

    def online_presence(to_jid)
      new_presence(:to => to_jid, :show => :chat)
    end

    def probe_presence(to_jid)
      new_presence(:to => to_jid, :type => :probe, :id => "id#{rand(9999)}")
    end

    def auth_presence(to_jid)
      new_presence(:to => to_jid, :type => :subscribe, :bare => true)
    end

    def subscribed_presence(to_jid)
      new_presence(:to => to_jid, :type => :subscribed, :bare => true)
    end

    def subscribe_presence(to_jid)
      new_presence(:to => to_jid, :type => :subscribe, :bare => true)
    end  
  end
end
