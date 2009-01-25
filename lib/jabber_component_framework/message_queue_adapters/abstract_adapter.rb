# ==============================
# = Default Roster Item Stores =
# ==============================
module Jabber::ComponentFramework::MessageQueueAdapters
  class ConnectionError < StandardError; end
  
  class AbstractAdapter

    def on_message(&block)
    end

    def enqueue(queue,message)
    end

  end
end