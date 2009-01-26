module Jabber
  module ComponentFramework    
    class ConnectionError; end
    
    class Controller
      class InitError < StandardError; end
      include Jabber

      VALID_COMPONENT_SETTINGS = [:host, :port, :component_jid, :password, :default_user,
        :debug, :log_messages_locally, :no_connect, :name, :auto_subscribe, :client,
        :presence_adapter, :roster_adapter, :message_adapter
      ]
      VALID_COMPONENT_SETTINGS.each do |setting|
        next if [:debug].include?(setting)
        attr_accessor setting
      end
      attr_reader :default_from

      # :host => "wonko.local", :component_jid => "chat.wonko.local", :password => "secret", :default_user => "workfeed", :debug => true, :log_messages_locally => true
      def initialize(options={})
        options = options.inject({}) do |suboptions, (key, value)|
          suboptions[key.to_sym || key] = value
          suboptions
        end

        invalid_options = options.keys - VALID_COMPONENT_SETTINGS
        raise InitError.new("Invalid options '#{invalid_options.join(',')}' passed to initialize") if invalid_options.any?

        VALID_COMPONENT_SETTINGS.each do |setting|
          self.send("#{setting}=",options[setting]) if options.has_key?(setting)
        end

        @port                 ||= 5560
        @host                 ||= 'localhost'
        @log_messages_locally ||= false
        @default_user         ||= "component"
        @default_from           = Jabber::JID.new("#{options[:default_user]}@#{component_jid}") if options[:default_user]

        unless options[:no_connect]
          puts "Connecting to Jabber Server @ #{host}:#{port}"
          connect!
          after_connect
        end
      end

      def connect!
        @client = begin
          client = Jabber::Component.new(component_jid)
          client.connect(host, port)
          client.auth(password)
          client
        end
      end
            
      def after_connect
        client.on_exception do |exception,stream,where|
          handle_exception(exception,stream,where)
        end
        register_default_callbacks
        start_message_sending_thread        
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
          send_with_retries(stanza,&block)
        end
      end

      def send_with_retries(msg,&block)
        attempts = 0
        begin
          attempts += 1
          client.send(msg,&block)
        rescue Errno::EPIPE, IOError => e
          sleep 1
          disconnect
          reconnect
          retry unless attempts > 3
          raise e
        rescue Errno::ECONNRESET => e
          sleep (attempts^2) * 60 + 60
          disconnect
          reconnect
          retry unless attempts > 3
          raise e
        end
      end

      alias_method :snd, :send!
      alias_method :send_xmpp, :send!

      def start_message_sending_thread
        return unless message_adapter
        pp "ADAMDEBUG: start_message_sending_thread"
        message_adapter.add_sent_message_callback do |q_message|
          deliver(q_message)
        end
      end

      def deliver(options={})
        return unless options
        if options.is_a?(Hash)
          message = jabber_message_from_options(options)
          if (!options[:stanza_type] || options[:stanza_type].to_s == "message")
            [options[:to]].flatten.each do |to|
              message.to = to.downcase
              puts "DELIVERING MESSAGE #{message.inspect}" if debug
              roster_item = roster.find_or_create(message.to)
              if options[:ignore_subscription] or roster_item.subscribed?
                send!(message)
              else
                # Request subscription if they are not subscribed
                roster_item.enqueue_deferred_messages(message)
                send! jid(message.from).auth_presence(message.to)
              end
            end
          else
            puts "DELIVERING MESSAGE #{message.inspect}" if debug
            send! message if message
          end
        else
          send! options
        end
      end

      def jabber_message_from_options(options)
        if (!options[:stanza_type] || options[:stanza_type].to_s == "message")
          message      = Jabber::Message.new
          message.body = options[:body]
          message.from = options[:from] || @default_from
          message.type = :chat
          message.to   = options[:to].downcase if options[:to] and options[:to].is_a?(String)
          [options[:xel]].flatten.each {|xel| message.add_element(xel)}  if options[:xel]
          message
        elsif options[:stanza_type].to_s == "presence"
          options[:from] ||= @default_from
          jid(options[:from]).new_presence(options)
        # elsif options[:stanza_type].to_s == "iq"
          # to do
        else
          puts "Stanza Type #{options[:stanza_type]} not supported"
          #unsupported
        end
      end


      def jid(newjid)
        Jabber::ComponentFramework::ComponentJID.new(newjid)
      end

      # This is workfeed specific
      CLIENT_TYPE_ID = 5
      def handle_message(message)
        case message.type
        when :chat
          return unless message.body
          begin
            return unless message_adapter
            puts "ENQ #{message.inspect}" if debug
            message_adapter.enqueue_received_message(message)
          rescue ConnectionError => e
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

      def handle_exception(exception,stream,where)
        puts "GOT EXCEPTION #{exception.inspect} #{stream} #{where} #{exception.backtrace.join("\n")}"
      end

      # XXX Maybe we should send this off to the component_jid or regular roster to handle.
      # Is it ok to see if the iq is for one of our component_jids?
      def handle_iq(iq)
        if iq.queryns == "jabber:iq:last"
          answer      = iq.answer
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
        @roster ||= ComponentFramework::Roster.new(roster_jid,:roster_adapter => roster_adapter, :presence_adapter => presence_adapter)
      end
      
      def auto_subscribe=(op)
        roster.auto_subscribe = op        
      end
      
      def auto_subscribe
        roster.auto_subscribe
      end

      def register_transport(un,pw,tjid)
        reg = Jabber::Iq.new_register(un, pw)
        reg.to = tjid
        reg.from = Jabber::JID.new("#{@default_from}/12345")
        send!(reg)
        send! jid("#{@default_from}/12345").online_presence(tjid)
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
