require "../storage"

class HTTPSession
  class Storage::Memory(T) < Storage(T)
    @storage = {} of String => Entry(T)

    def fetch(session_id : String) : Entry(T)?
      @storage[session_id]?
    end

    def put(session_id : String, entry : Entry(T)) : Nil
      @storage[session_id] = entry
    end

    def delete(session_id : String) : Nil
      @storage.delete(session_id)
    end

    def delete_expired(min : Time) : Nil
      @storage.select! { |_, entry| entry.valid?(min) }
    end

    # Generates a new unused session_id.
    #
    # This is a basic implementation
    def new_session_id : String
      Manager.new_session_id { |id| !has?(id) }
    end
  end
end
