# ==============================
# = Default Roster Item Stores =
# ==============================
module Jabber::ComponentFramework::MessageAdapters
  class Memory < AbstractAdapter
    
    class << self
    
      def queues
        @queues ||= {"xmpp_received_messages" => Queue.new, "xmpp_sent_messages" => Queue.new}
      end            
    
      def enqueue(message,queue)
        queues[queue].push message
      end

      # Messages received via xmpp are enqueued here
      def enqueue_received_message(message,queue="xmpp_received_messages")
        enqueue(message,queue)
      end

      # messages you want sent via xmpp should be enqueued here
      def enqueue_sent_message(message,queue="xmpp_sent_messages")
        enqueue(message,queue)
      end

      # Register a callback for messages received via xmpp
      def add_received_message_callback(queue="xmpp_received_messages")
        @received_thread = Thread.new do
          loop do
            msg = queues[queue].pop
            yield msg
          end
        end
      end

      # Controller uses this callback to listen to the sent_message_queue
      def add_sent_message_callback(queue="xmpp_sent_messages")
        @sent_thread = Thread.new do
          loop do
            yield queues[queue].pop
          end
        end
      end
      
    end
  end
end