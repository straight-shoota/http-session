class HTTPSession
  abstract class Storage
    def [](session_id : String) : HTTPSession?
      if session = fetch(session_id)
        if session.valid?(Time.utc - max_age)
          session
        end
      end
    end

    def new_session(session_id : String)
      HTTPSession.new(session_id).tap do |session|
        put(session)
      end
    end

    abstract def put(session : HTTPSession) : Nil

    abstract def delete(session_id : String) : Nil

    abstract def fetch(session_id : String) : HTTPSession?

    abstract def delete_expired(min : Time) : Nil

    property gc_interval : Time::Span = 4.hours
    property max_age : Time::Span = 48.hours

    def run_gc_loop
      loop do
        sleep gc_interval

        min_time = now - max_age
        delete_expired(min_time)
      end
    end
  end
end

require "./storage/memory"
