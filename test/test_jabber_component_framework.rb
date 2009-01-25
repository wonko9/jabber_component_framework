require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/client_tester'
 
class TestJabberComponentFramework < Test::Unit::TestCase
  include Jabber  
  # include ClientTester
  @@SOCKET_PORT = 65224
  STREAM = 'stream:stream xmlns:stream="http://etherx.jabber.org/streams"'
  
  def setup
    servlisten = TCPServer.new(@@SOCKET_PORT)
    serverwait = Semaphore.new
    Thread.new do
      Thread.current.abort_on_exception = true
      serversock = servlisten.accept
      servlisten.close
      serversock.sync = true
      @server = Stream.new
      @server.add_xml_callback do |xml|
        if xml.prefix == 'stream' and xml.name == 'stream'
          @server.send("<#{STREAM} xmlns='jabber:component:accept'>")
          true
        else
          false
        end
      end
      @server.start(serversock)
  
      serverwait.run
    end
  
    @stream = Component.new('test')
    @stream.connect('localhost', @@SOCKET_PORT)
  
    serverwait.wait
  end
  
  def teardown
    @stream.close
    @server.close
  end
   

  test "controller" do       
    
    assert c = Jabber::ComponentFramework::Controller.new(:no_connect => true, :port => @@SOCKET_PORT)
    assert_equal c.roster.roster_adapter, Jabber::ComponentFramework::RosterAdapters::Memory
    assert_equal c.roster.presence_adapter, Jabber::ComponentFramework::PresenceAdapters::Memory
    c.after_connect
    
   
    
  end
end