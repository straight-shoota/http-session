class HTTPSession
  # Defines the storage backend interface used by `HTTPSession::Manager`.
  abstract module StorageInterface(T)
    # Fetches the storage value for *session_id*.
    # Returns `nil` if no value exists.
    abstract def [](session_id : String) : T?

    # Returns true if *session_id* exists.
    def has?(session_id : String) : Bool
      !self[session_id].nil?
    end

    # Sets the storage value for *session_id*.
    abstract def []=(session_id : String, session : T) : Nil

    # Deletes the storage value for *session_id*.
    abstract def delete(session_id : String) : Nil
  end

  # A base class for implementing storage backends.
  abstract class Storage(T)
    include StorageInterface(T)

    # Represents a session value in a `Storage` backend.
    struct Entry(T)
      getter value, created_at, touched_at

      def initialize(@value : T, @created_at : Time = Time.utc, @touched_at : Time = created_at)
      end

      # Returns `true` if `touched_at` is younger than *min*.
      def valid?(min : Time)
        @touched_at > min
      end

      # Updates `session_touched_at` to `Time.utc`.
      def touch
        @touched_at = Time.utc
      end
    end

    # The interval for deleting expired session values.
    property gc_interval : Time::Span = 4.hours

    # The maximum age.
    property max_age : Time::Span = 48.hours

    # Fetches an entry indicated by *session_id*.
    # Returns `nil` if no entry exists.
    abstract def fetch(session_id : String) : Entry(T)?

    # Sets the entry for *session_id*.
    abstract def put(session_id : String, entry : Entry(T)) : Nil

    # Deletes all expired storage values, i.e. which have not been touched since *time*.
    abstract def delete_expired(min : Time) : Nil

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

    # Runs a loop that call `delete_expired` every interval of `gc_interval`.
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
