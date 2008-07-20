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
      
      AVATAR = "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\nAElFTkSuQmCC\n"
      def vcard_template
        @vcard_template ||= begin
          my_vcard                 = Jabber::Vcard::IqVcard.new
          my_vcard["FN"]           = "Workfeed"
          my_vcard["NICKNAME"]     = "Workfeed"
          my_vcard["ORG/ORGNAME"]  = "Workfeed Inc."          
          my_vcard["BDAY"]         = "1976-06-24"          
          my_vcard["URL"]          = "http://www.workfeed.com"
          my_vcard["EMAIL"]        = "update@workfeed.com"
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