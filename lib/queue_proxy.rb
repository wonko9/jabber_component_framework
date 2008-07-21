require 'rubygems'
require 'starling'
require 'timeout'

class QueueProxy
  
  # QUEUE_ENABLED = true unless defined?(QUEUE_ENABLED)
  
  class ConnectionError < StandardError; end

  attr_accessor :queue_client
  def initialize(options={})
    @host = options[:host] || '127.0.0.1'
    @port = options[:port] || '22122'
    @queue_client = Starling.new("#{@host}:#{@port}")
  end
  
  def register_queue_poller(queue_name, &block)
    thread = Thread.new do
      poll_queue(queue_name,&block)
    end
    thread
  end

  def poll_queue(queue_name)
    queue_retry = 0
    loop do
      begin
        yield self.get(queue_name)
      rescue QueueProxy::ConnectionError => e
        puts "Failed to read from queue #{queue_name}" + e.message + " retry #{queue_retry}"
        queue_retry += 1
        self.exit if queue_retry > 100
        sleep 1              
      rescue Exception => e
        puts "SOMETHING BAD HAPPENED #{e.class} #{e.message} #{e.backtrace.join("\n")}"
      end
    end
  end
  
  def queue_server_host
    "#{@host}:#{@port}"
  end    
  
  def enqueue(queue,message)
    begin
      queue_client.set(queue,message)
    rescue MemCache::MemCacheError => e
      raise ConnectionError.new("Could not connect to '#{queue}' queue #{e.inspect}")
    end
  end
  
  def dequeue(queue)
    begin
      queue_client.get(queue)
    rescue MemCache::MemCacheError => e
      raise ConnectionError.new("Could not connect to '#{queue}' queue #{e.inspect}")
    end
  end    

  # Depth should be passed a queue name (returns int) or :all (returns hash of name=>int pairs)
  def depth(queue)
    queue_client.sizeof(queue)
  end

  alias_method :set, :enqueue
  alias_method :get, :dequeue
end
