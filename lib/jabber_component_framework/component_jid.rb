SITE_NAME    = "Yammer"             unless defined?(SITE_NAME)
SITE         = "www.yammer.com"     unless defined?(SITE)
UPDATE_EMAIL = "yammer@yammer.com"  unless defined?(UPDATE_EMAIL)

module Jabber
  module ComponentFramework
    class ComponentJID < Jabber::JID
      include Jabber

      def initialize(jid,options={})
        super(jid)
        if options[:avatar_file]
          @avatar = Base64.encode64(File.open("public/images/#{avatar_file}").read)
        end
        self.resource ||= "none"
      end
      
      AVATAR = "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\nwQ0AAAAASUVORK5CYII=\n"
      def vcard_template
        @vcard_template ||= begin
          my_vcard                 = Jabber::Vcard::IqVcard.new
          my_vcard["FN"]           = "#{SITE_NAME}"
          my_vcard["NICKNAME"]     = "#{SITE_NAME}"
          my_vcard["ORG/ORGNAME"]  = "#{SITE_NAME} Inc."          
          my_vcard["BDAY"]         = "1976-06-24"          
          my_vcard["URL"]          = "http://#{SITE}"
          my_vcard["EMAIL"]        = UPDATE_EMAIL
          my_vcard["PHOTO/TYPE"]   = 'image/png'
          my_vcard["PHOTO/BINVAL"] = @avatar || AVATAR
          my_vcard["DESC"]         = "What are you working on? I'm just trying to keep up with all of your messages!"
          my_vcard
        end
      end

      def vcard(to_jid)
        iq_response      = Jabber::Iq.new
        iq_response.to   = to_jid
        iq_response.from = self
        iq_response.type = :result
        iq_response.add_element vcard_template
        iq_response
      end          

      def vcard_response(iq_request)
        vcard_response    = vcard(iq_request.from)
        vcard_response.id = iq_request.id
        vcard_response
      end

    end # end JID
  end
end
