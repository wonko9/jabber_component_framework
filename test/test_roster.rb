require File.dirname(__FILE__) + '/test_helper.rb'

class TestRoster < Test::Unit::TestCase  
  include Jabber
  
  def setup
    Jabber::ComponentFramework::RosterAdapters::Memory.clear
    Jabber::ComponentFramework::PresenceAdapters::Memory.clear    
  end
    
  test "handle presence" do
    roster = get_roster
    pres = Presence.new
    pres.from = JID.new("from@guy.com")
    pres.to = jid
    
    ri = roster.find_or_create(pres.from)
    # not online or offline yet
    assert !ri.online?
    assert !ri.offline?
    assert :unknown, ri.presence.availability
    
    roster.handle_presence(pres)
    
    ri = roster.find_or_create(pres.from)
    assert ri.subscribed?
    assert ri.online?

    pres.type = :subscribe
    assert roster.handle_presence(pres)
    assert ri.online?
    assert ri.subscribed?
    
    pres.type = :unsubscribe
    assert roster.handle_presence(pres)
    assert !ri.online?
    assert !ri.subscribed?
    
    
  end
  
  test "roster items" do
    roster = get_roster
    assert !roster.find(jid)

    ri = roster.find_or_create(jid)
    assert ri
    assert !ri.subscribed?
    
    ri.online!
    assert ri.subscribed?
    assert ri.online?
    
    ri.offline!
    assert !ri.online?
    assert ri.subscribed?
    
    ri.unsubscribe!
    assert !ri.online?
    assert !ri.subscribed?
  end
  
  
  test "roster memory store" do
    klass = Jabber::ComponentFramework::RosterAdapters::Memory
    assert !klass.find(jid)
    j = klass.create(jid)
    assert klass.find(jid)
    assert !j.subscribed
    
    j.enqueue_deferred_messages([:test])
    j = klass.find(jid)
    assert_equal j.dequeue_deferred_messages, [:test]
    
  end
  
  def jid
    JID.new("adam@blah.com")
  end
  
  def get_roster
    Jabber::ComponentFramework::Roster.new("happy@sad.com")
  end
  
  
  
  
  
end