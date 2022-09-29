require "http"
require "./storage"

class HTTPSession
  class Manager(T)
    # Configures the basic properties of the cookie used for
    # communicating the session id to the client.
    getter cookie_prototype : HTTP::Cookie

    # Returns the storage engine.
    getter storage : StorageInterface(T)

    # Creates a new session handler.
    #
    # *cookie_prototype* configures the basic properties of the cookie used for
    # communicating the session id to the client.
    # It uses a secure configuration by default. This configuration can be even
    # more restricted (for example via `Domain` and `Path` properties) depending
    # on use case.
    # Lifting the default restrictions is not recommended.
    # Cookies are not persistent by default, thus they are expected to disappear at
    # the end of a browser session. Add `Max-Age` or `Expires` header for
    # persistent cookies.
    def initialize(@storage : Storage(T), @cookie_prototype = HTTP::Cookie.new("session_id", "", secure: true, http_only: true, samesite: :strict))
    end

    # Returns the name of the cookie used to communicate the session id to the
    # client.
    #
    # This value is configurable through `cookie_prototype`.
    def cookie_name
      cookie_prototype.name
    end

    # Terminates the session associated with the context.
    #
    # Removes the session cookie and deletes the session from storage.
    def delete(context : HTTP::Server::Context)
      if session_id = session_id(context)
        @storage.delete(session_id)
        context.response.cookies.delete(cookie_name)
      end
    end

    def get(context : HTTP::Server::Context) : T?
      if session_id = session_id(context)
        @storage[session_id]
      end
    end

    # Sets the session for *context* to *session*.
    def set(context : HTTP::Server::Context, session : T) : Nil
      set(context, session) { }
    end

    # Sets the session for *context* to *session*.
    # Yields if *context* has a session_id that doesn't exist in the backend.
    # This can be useful for detecting malicious behaviour or entirely rejecting
    # requests with a bad session_id.
    #
    # ```
    # manager.set(context, user_session) do |bad_session_id|
    #   Log.warn &.emit("Bad session_id used", bad_session_id: bad_session_id)
    # end
    # ```
    def set(context : HTTP::Server::Context, session : T, & : String -> _) : Nil
      session_id = session_id(context)
      unless session_id && @storage.has?(session_id)
        yield session_id if session_id
        session_id = @storage.new_session_id

        cookie = cookie_prototype.dup
        cookie.value = session_id
        context.response.cookies << cookie
      end

      @storage[session_id] = session
    end

    private def session_id(context)
      context.request.cookies[cookie_name]?.try(&.value) || context.response.cookies[cookie_name]?.try(&.value)
    end

    # Random source for generating session IDs.
    #
    # This should be a cryptographically secure pseudorandom number generator (CSPRNG).
    class_property random : Random = Random::Secure

    # Generates a new session_id.
    #
    # Potential values are passed to the block which is supposed to return `true`
    # when the session_id is good and unused.
    def self.new_session_id(session_id_length : Int32 = 16, & : String -> Bool)
      100.times do
        new_id = random.urlsafe_base64(session_id_length)
        # ensure uniqueness
        return new_id if yield(new_id)
      end

      raise RuntimeError.new("Failed to generate unique session ID")
    end
  end
end
