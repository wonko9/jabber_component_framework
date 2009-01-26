require 'rubygems'
require 'memcache'
require 'starling'
                                                                                              # ==============================
# = Default Roster Item Stores =
# ==============================
module Jabber::ComponentFramework::MessageAdapters
  class Starling < AbstractAdapter
    
    attr_accessor :queue_client
    attr_reader :sent_message_queue, :received_message_queue
    def initialize(options={})
      @sent_message_queue     = options[:sent_message_queue] || "xmpp_sent_messages"
      @received_message_queue = options[:received_message_queue]  || "xmpp_received_messages"
      @host = options[:host] || '127.0.0.1'
      @port = options[:port] || '22122'
      @queue_client = MemCache.new("#{@host}:#{@port}")
    end
    
    # Messages received via xmpp are enqueued here
    def enqueue_received_message(message,queue=received_message_queue)
      enqueue(message,queue)
    end

    # messages you want sent via xmpp should be enqueued here
    def enqueue_sent_message(message,queue=sent_message_queue)
      enqueue(message,queue)
    end

    def enqueue(message,queue)
      begin
        queue_client.set(queue,message)
      rescue MemCache::MemCacheError => e
        raise ConnectionError.new("Could not connect to '#{queue}' queue #{e.inspect} #{e.backtrace.join("\n")}")
      end
    end

    # Register a callback for messages received via xmpp
    def add_received_message_callback(queue=received_message_queue,&block)
      @received_thread = Thread.new do
        poll_queue(queue,&block)
      end
    end

    # Controller uses this callback to listen to the sent_message_queue
    def add_sent_message_callback(queue=sent_message_queue,&block)
      @sent_thread = Thread.new do
        poll_queue(queue,&block)
      end
    end

    def poll_queue(queue_name)
      queue_retry = 0
      loop do
        begin
          yield queue_client.get(queue_name)
        rescue MemCache::MemCacheError => e
          puts "Failed to read from queue #{queue_name}" + e.message + " retry #{queue_retry}"
          queue_retry += 1
          self.exit if queue_retry > 100
          sleep 1              
        rescue Exception => e
          puts "SOMETHING BAD HAPPENED #{e.class} #{e.message} #{e.backtrace.join("\n")}"
        end
      end
    end    

  end
end