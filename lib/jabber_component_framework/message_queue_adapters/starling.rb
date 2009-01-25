                                                                                              # ==============================
# = Default Roster Item Stores =
# ==============================
module Jabber::ComponentFramework::MessageQueueAdapters
  class Starling < AbstractAdapter
    
    attr_accessor :queue_client
    attr_reader :sent_message_queue, :received_message_queue
    def initialize(options={})
      @sent_message_queue     = options[:sent_message_queue]
      @received_message_queue = options[:received_message_queue]
      @host = options[:host] || '127.0.0.1'
      @port = options[:port] || '22122'
      @queue_client = Starling.new("#{@host}:#{@port}",options)
    end
    
    def handle_received_message(message,queue=received_message_queue)
      begin
        queue_client.set(queue,message)
      rescue MemCache::MemCacheError => e
        raise ConnectionError.new("Could not connect to '#{queue}' queue #{e.inspect} #{e.backtrace.join("\n")}")
      end
    end

    def add_sent_message_callback(queue=sent_message_queue,&block)
      thread = Thread.new do
        poll_queue(queue,&block)
      end
      thread
    end

    def poll_queue(queue_name)
      queue_retry = 0
      loop do
        begin
          yield self.get(queue_name)
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