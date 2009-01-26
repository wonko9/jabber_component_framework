module Jabber
  class JID

    def self.return_or_new(node = "", domain = nil, resource = nil)
      return node if node.is_a?(Jabber::JID)
      node     = node.downcase     if node
      resource = resource.downcase if resource
      domain   = domain.downcase   if domain
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
      if pres.type == :probe and not pres.id
        pres.id = rand(9999).to_s
      end
      pres
    end

    def online_presence(to_jid)
      new_presence(:to => to_jid)
    end

    def probe_presence(to_jid)
      new_presence(:to => to_jid, :type => :probe, :id => "id#{rand(9999)}")
    end

    def auth_presence(to_jid)
      new_presence(:to => to_jid, :type => :subscribe, :bare => true)
    end
    alias_method :subscribe_presence, :auth_presence

    def subscribed_presence(to_jid)
      new_presence(:to => to_jid, :type => :subscribed, :bare => true)
    end

    def subscribe_presence(to_jid)
      new_presence(:to => to_jid, :type => :subscribe, :bare => true)
    end

    def message_to(to_jid,options={})
      message      = Jabber::Message.new
      message.from = self
      message.to   = to_jid
      message.type = :chat
      options.each {|k,v| message.send("#{k}=",v)}
      message
    end

    def iq_to(to_jid,options={})
      iq_response      = Jabber::Iq.new
      iq_response.to   = to_jid
      iq_response.from = self
      iq_response.type = :result
      options.each {|k,v| iq_response.send("#{k}=",v)}
      iq_response
    end

  end
end
