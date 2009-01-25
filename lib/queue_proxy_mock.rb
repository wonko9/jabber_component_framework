require 'rubygems'

class QueueProxyMock

  def initialize
    @queues = {}
  end
          
  def enqueue(queue,message)
    @queues[queue] ||= Queue.new
    @queues[queue].push(message)
  end
  
  def dequeue(queue)
    @queues[queue] ||= Queue.new
    @queues[queue].pop
  end 
  
  def empty?(queue)
    @queues[queue] ||= Queue.new
    @queues[queue].empty?
  end    

  def clear(queue)
    @queues[queue] ||= Queue.new      
    @queues[queue].clear
  end        

  alias_method :set, :enqueue
  alias_method :get, :dequeue
end