require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/client_tester'
require 'mocha'

class TestJabberComponentFramework < Test::Unit::TestCase
  include Jabber
  # include ClientTester
  @@SOCKET_PORT = 65224
  
  def setup_controller(options={})
    Jabber::Component.any_instance.stubs(:connect).returns(true)
    Jabber::Component.any_instance.stubs(:auth).returns(true)
    Jabber::Component.any_instance.stubs(:is_connected?).returns(true)
    c = Jabber::ComponentFramework::Controller.new(options.merge(:port => @@SOCKET_PORT, :component_jid => "test.test", :default_user => "testee"))
    @c = c
    @cjid = @c.default_from
    @client = c.client
    
    def @client.send(msg,&block)
      @sent_messages ||= []
      @sent_messages << msg      
    end                    

    def @client.sent_messages
      @sent_messages
    end                            
  end
  
  def test_default_callbacks
    setup_controller
    @c.expects(:handle_presence).times(1)
    @c.expects(:handle_message).times(1)
    @c.expects(:handle_iq).times(1)
    j = JID.new("someguy@guy.com")

    pres = j.subscribe_presence(@cjid)
    @c.client.presence_callbacks.process(pres)

    message = j.message_to(@cjid)
    @c.client.message_callbacks.process(message)

    iq = j.iq_to(@cjid)
    @c.client.iq_callbacks.process(iq)
    
  end
  

  def test_presence
    setup_controller
    assert_equal @c.roster.roster_adapter, Jabber::ComponentFramework::RosterAdapters::Memory
    assert_equal @c.roster.presence_adapter, Jabber::ComponentFramework::PresenceAdapters::Memory
    j = JID.new("from@from.com/testresource")
            
    pres = j.subscribe_presence(@cjid)
    @c.client.presence_callbacks.process(pres)    
    assert !@c.roster[pres.from]
    # 
    @c.auto_subscribe = true
    @c.client.presence_callbacks.process(pres)
    assert @c.roster[pres.from].subscribed?
    
  end
  
  def test_memory_message_queue
    setup_controller(:message_adapter => Jabber::ComponentFramework::MessageAdapters::Memory)
    received_messages = []
    Jabber::ComponentFramework::MessageAdapters::Memory.add_received_message_callback do |message|
      received_messages << message
    end
    j = JID.new("someguy@guy.com")
    
    message = j.message_to(@cjid,:body => "hi")
    @c.client.message_callbacks.process(message)
    assert_equal 1, received_messages.size
    
    Jabber::ComponentFramework::MessageAdapters::Memory.enqueue_sent_message(message)
    assert_equal message, @c.client.sent_messages.first
    
  end

end

class Jabber::Stream
  # Get the list of iq callbacks.
  def iq_callbacks
    @iqcbs
  end

  ##
  # Get the list of message callbacks.
  def message_callbacks
    @messagecbs
  end

  ##
  # Get the list of presence callbacks.
  def presence_callbacks
    @presencecbs
  end

  ##
  # Get the list of stanza callbacks.
  def stanza_callbacks
    @stanzacbs
  end

  ##
  # Get the list of xml callbacks.
  def xml_callbacks
    @xmlcbs
  end
end
