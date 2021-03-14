class HTTPSession
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
end
