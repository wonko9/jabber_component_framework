require File.dirname(__FILE__) + '/test_helper.rb'
require 'mocha'

class TestJabberComponentFramework < Test::Unit::TestCase
  include Jabber
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

  def setup_memory_adapters
    @c.roster_adapter   = Jabber::ComponentFramework::RosterAdapters::Memory
    @c.presence_adapter = Jabber::ComponentFramework::PresenceAdapters::Memory
    assert_equal @c.roster.roster_adapter, Jabber::ComponentFramework::RosterAdapters::Memory
    assert_equal @c.roster.presence_adapter, Jabber::ComponentFramework::PresenceAdapters::Memory
    @c.roster.presence_adapter.clear
    @c.roster.roster_adapter.clear
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
    setup_memory_adapters
    j = JID.new("from@from.com/testresource")

    pres = j.subscribe_presence(@cjid)
    @c.client.presence_callbacks.process(pres)
    assert !@c.roster[pres.from]
    #
    @c.auto_subscribe = true
    @c.client.presence_callbacks.process(pres)
    assert @c.roster[pres.from].subscribed?
  end

  def test_deferred_messags
    setup_controller(:auto_subscribe => true, :ignore_subscriptions => false)
    setup_memory_adapters
    j = JID.new("from@from.com/testresource")
    m = @cjid.message_to(j,:body => "hi")
    @c.deliver(m)
    assert_equal j.bare.to_s, @c.roster.roster_adapter.deferred_messages.keys.first
    assert_equal 1, @c.client.sent_messages.size
    assert_equal :subscribe, @c.client.sent_messages.first.type

    @c.ignore_subscriptions = true
    @c.deliver(m)
    assert_equal 2, @c.client.sent_messages.size
    assert_equal :chat, @c.client.sent_messages.last.type

  end

  def test_memory_message_queue
    setup_controller(:message_adapter => Jabber::ComponentFramework::MessageAdapters::Memory, :ignore_subscriptions => true)
    setup_memory_adapters

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

  def test_noop_adapters
    setup_controller(:auto_subscribe => false, :ignore_subscriptions => true)
    assert_equal @c.roster.roster_adapter, Jabber::ComponentFramework::RosterAdapters::Noop
    assert_equal @c.roster.presence_adapter, Jabber::ComponentFramework::PresenceAdapters::Noop
    j = JID.new("from@from.com/testresource")
    assert ri = @c.roster[j.to_s]
    assert ri.subscribed?
    assert ri.online?

    m = @cjid.message_to(j,:body => "hi")
    @c.deliver(m)
    assert_equal 1, @c.client.sent_messages.size
    assert_equal :chat, @c.client.sent_messages.first.type

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
