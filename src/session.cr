# `HTTPSession` represents the data associated with a session. It's meant to
# be reopened to add application specific properties.
# For using persistent storage, the properties need to be compatible with the
# serialization mechanism of the employed storage engine (for example provide
# DB bindings or implement `JSON::Serializable`).
#
# It is recommended to prefix custom properties with the name of the shard to avoid
# conflicts when different libraries could introduce homonymous properties.
class HTTPSession
  Log = Log.for("http.session")

  getter session_id : String
  getter session_created_at : Time
  getter session_touched_at : Time

  def initialize(@session_id : String)
    @session_touched_at = @session_created_at = Time.utc
  end

  # Returns `true` if `session_touched_at` is younger than *min*.
  def valid?(min : Time)
    @session_touched_at > min
  end

  # Updates `session_touched_at` to `Time.utc`.
  def touch
    @session_touched_at = Time.utc
  end
end
