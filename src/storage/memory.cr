require "../storage"

class HTTPSession
  class Storage::Memory < HTTPSession::Storage
    @storage = {} of String => HTTPSession

    def fetch(session_id : String) : HTTPSession?
      @storage[session_id]?
    end

    def put(session : HTTPSession) : Nil
      @storage[session.session_id] = session
    end

    def delete(session_id : String) : Nil
      @storage.delete(session_id)
    end

    def delete_expired(min : Time) : Nil
      @storage.select! { |_, session| session.valid?(min) }
    end
  end
end
