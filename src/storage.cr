class HTTPSession
  # Implementing types are expected to implement these methods based on `Entry`.
  # They are not enforced because you can decide to override the
  # implementations of `#[]`, `#[]=` and `#run_gc_loop` directly instead.
  #
  # ```
  # abstract def fetch(session_id : String) : Entry(T)?
  # abstract def put(session_id : String, session : Entry(T)) : Nil
  # abstract def delete_expired(min_time : Time) : Nil
  # ```
  abstract class Storage(T)
    property gc_interval : Time::Span = 4.hours
    property max_age : Time::Span = 48.hours

    abstract def delete(session_id : String) : Nil

    def [](session_id : String) : T?
      if entry = fetch(session_id)
        if entry.valid?(Time.utc - max_age)
          entry.value
        else
          delete(session_id)
          nil
        end
      end
    end

    def []=(session_id : String, session : T) : Nil
      put(session_id, Entry.new(session))
    end

    def run_gc_loop
      loop do
        sleep gc_interval

        min_time = Time.utc - max_age
        delete_expired(min_time)
      end
    end
  end
end

require "./storage/memory"
