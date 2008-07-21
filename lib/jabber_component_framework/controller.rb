module Jabber
  module ComponentFramework
    class Controller
      class InitError < StandardError; end
      include Jabber            

      VALID_COMPONENT_SETTINGS = [
        :server, :port, :component_jid, :password, :default_user,
        :log_messages_locally, :no_connect, :name, :debug
      ]
      
      VALID_COMPONENT_SETTINGS.each do |setting|
        next if setting == :debug
        attr_accessor setting
      end

      attr_reader :delivery_thread, :client

      # :server => "localhost", :component_jid => "chat.mydomain.com", :password => "secret", :default_user => "somebot@chat.mydomain.com", :debug => true, :log_messages_locally => true
      def initialize(options)
        options = options.inject({}) do |suboptions, (key, value)|
          suboptions[key.to_sym || key] = value
          suboptions
        end  

        invalid_options = options.keys - VALID_COMPONENT_SETTINGS
        raise InitError.new("Invalid options '#{invalid_options.join(',')}' passed to initialize") if invalid_options.any?
        
        VALID_COMPONENT_SETTINGS.each do |setting|
          self.send("#{setting}=",options[setting]) if options.has_key?(setting)
        end
        @port ||= 5560
        @default_from  = Jabber::JID.new("#{options[:default_user]}@#{component_jid}")
        @log_messages_locally ||= false

        puts "Connecting to Jabber Server @ #{server}:#{port}"
        unless options[:no_connect]
          connect!
          client.on_exception do |exception|
            handle_exception(exception)
          end
          register_default_callbacks
          start_message_sending_thread
        end
      end
  
      def start_message_sending_thread
        @delivery_thread = MessageQueue.proxy.register_queue_poller("outbound_im") do |q_message|
          deliver(q_message)
        end
      end
      
      def deliver(options={})
        message      = Jabber::Message.new
        message.to   = options[:to]
        message.body = options[:body]
        message.from = options[:from] || @default_from

        if options[:xel]
          [options[:xel]].flatten.each {|xel| message.add_element(xel)} 
        end
    
        puts "DELIVERING MESSAGE #{message.inspect}" if debug
        roster_item = roster.find(message.to)
        
        # XXX we've talked about having a NON persistent roster_item version.

        if roster_item.subscribed?
          send!(message)
        else
          # Request subscription if they are not subscribed
          roster_item.add_pending_auth_message(message)
          send! jid(message.from).auth_presence(message.to)
        end
      end

      def connect!
        @client = begin
          client = Jabber::Component.new(component_jid)
          client.connect(server, port)
          client.auth(password)
          client
        end
      end
  
      def disconnect!
        @client.close
      end
      
      def reconnect!
        begin
          disconnect!
        rescue IOError
        end
        connect!
        client.delete_message_callback("comp_msg_cb")
        client.delete_iq_callback("comp_iq_cb")
        client.delete_presence_callback("comp_pres_cb")        
        register_default_callbacks
      end
      
      def connected?
        client.is_connected?
      end
      
      def is_connected?
        client.is_connected?
      end
      
      def close
        disconnect!
      end

      def send!(stanzas,&block)
        if not connected?
          reconnect!
        end        
        stanzas = [stanzas].flatten
        stanzas.each do |stanza|
          client.send(stanza,&block)
        end
      end

      def jid(newjid)
        Jabber::ComponentFramework::ComponentJID.new(newjid)
      end

      # This is app specific :(
      CLIENT_TYPE_ID = 5 
      def handle_message(message)
        case message.type
        when :chat
          return unless message.body
          q_message = {
            :client_type_id => CLIENT_TYPE_ID,
            :client_id      => message.from.strip.to_s,
            :body           => message.body,
          }
          begin
            enqueue("inbound_messages", q_message)
          rescue QueueProxy::ConnectionError => e
            # XXX What do we do here?
            puts e.message
            sleep 1
          end          
        when :error
          puts "GOT ERROR MESSAGE #{message.error.code}"
          case message.error.code
          when 404, 502, 503
            roster[message.from].offline!
          else
            puts "Message Error #{message.inspect}"
          end
        end
      end
            
      def handle_exception(exception)
        puts "GOT EXCEPTION #{exception.inspect}"
      end
            
      # XXX Maybe we should send this off to the component_jid or regular roster to handle.
      # Is it ok to see if the iq is for one of our component_jids?
      def handle_iq(iq)        
        if iq.queryns == "jabber:iq:last"
          answer = iq.answer
          answer.type = :result
          answer.query.add_attribute("seconds","0")
          send! answer
          
        elsif iq.query.kind_of?(Jabber::Discovery::IqQueryDiscoInfo)
          send! disco_info(iq)
        elsif iq.query.kind_of?(Jabber::Discovery::IqQueryDiscoItems)
          # XXX What should we send here?
          # send! disco_info(iq)
        elsif iq.vcard
          send! jid(iq.to).vcard_response(iq)
        end
      end      
            
      def handle_presence(presence)
        # This handles setting online/offline/subscribed/unsubscribed
        response = roster.handle_presence(presence)
        send!(response) if response        
      end
      
      attr_accessor :presences, :messages, :iqs
            
      def register_default_callbacks
        if log_messages_locally
          @presences ||= []
          @messages  ||= []
          @iqs       ||= []
        end
        
        client.add_message_callback(0,"comp_msg_cb") do |message|
          @messages << message if log_messages_locally
          handle_message(message)
        end

        client.add_presence_callback(0,"comp_pres_cb") do |presence|
          @presences << presence if log_messages_locally
          handle_presence(presence)
        end

        client.add_iq_callback(0,"comp_iq_cb") do |iq|
          @iqs << iq if log_messages_locally
          handle_iq(iq)
        end           
        
      end
  
      def roster(roster_jid=@default_from)
        @roster ||= ComponentFramework::Roster.new(roster_jid)
      end

      def enqueue(queue,message)
        puts "ENQ #{queue} #{message.inspect}" if debug
        MessageQueue.proxy.set(queue,message)
      end
  
      def dequeue(queue)
        MessageQueue.proxy.get(queue)
      end
      
      def register_transport(un,pw,tjid)
        reg = Jabber::Iq.new_register(un, pw)
        reg.to = tjid
        reg.from = Jabber::JID.new("#{@default_from}/12345")
        send!(reg)
        send! jid("#{@default_from}/12345").online_presence(tjid)
      end

      def register_aim
        register_transport("wfadamtest2","fl0b0t","aim.wonko.local")
      end

      def disco_info(iq)
        answer = iq.answer
        answer.type = :result                     
        answer.query.add(Jabber::Discovery::Feature.new('jabber:iq:version'))
        answer.query.add(Jabber::Discovery::Identity.new('client', name, 'bot'))        
        answer.query.add(Jabber::Discovery::Identity.new('component', name, 'sm')) # user session component
        answer.query.add(Jabber::Discovery::Identity.new('component', name, 'presence')) # user session component
        # answer.query.add(Jabber::Discovery::Identity.new('component', name, 's2s')) # user session component
        answer.query.add(Jabber::Discovery::Identity.new('component', name, 'generic')) # user session component
        answer.query.add(Jabber::Discovery::Identity.new('component', name, 'load')) # user session component
        answer
      end

      def debug=(d)
        Jabber::debug = d
      end
      
      def debug
        Jabber::debug
      end
          
      def send_status_to_roster(status)
        roster.each do |roster_jid|
          pres = Jabber::Presence.new(:chat,"available")
          pres.to = roster_jid
          pres.from = component_jid
          client.send(pres)
        end
      end
    end
  end
end
