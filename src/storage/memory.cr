require "../storage"

class HTTP::Session::Storage::Memory < HTTP::Session::Storage
  @storage = {} of String => Session

  def fetch(session_id : String) : Session?
    @storage[session_id]?
  end

  def put(session : Session) : Nil
    @storage[session.session_id] = session
  end

  def delete(session_id : String) : Nil
    @storage.delete(session_id)
  end

  def delete_expired(min : Time) : Nil
    @storage.select! { |_, session| session.valid?(min) }
  end
end
