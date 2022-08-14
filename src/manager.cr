require "http"
require "./entry"
require "./storage"

class HTTPSession
  class Manager(T)
    # Random source for generating session IDs.
    #
    # This should be a cryptographically secure pseudorandom number generator (CSPRNG).
    property random : Random = Random::Secure

    # Configures the basic properties of the cookie used for
    # communicating the session id to the client.
    getter cookie_prototype : HTTP::Cookie

    # Returns the storage engine.
    getter storage : StorageInterface(T)

    # Length of generated session IDs in bytes.
    property session_id_length = 16

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

    def set(context : HTTP::Server::Context, session : T) : Nil
      session_id = session_id(context)
      unless session_id && @storage[session_id]
        session_id = new_session_id

        cookie = cookie_prototype.dup
        cookie.value = session_id
        context.response.cookies << cookie
      end

      @storage[session_id] = session
    end

    private def session_id(context)
      context.request.cookies[cookie_name]?.try(&.value) || context.response.cookies[cookie_name]?.try(&.value)
    end

    private def new_session_id
      100.times do
        new_id = random.urlsafe_base64(session_id_length)
        # ensure uniqueness
        return new_id unless @storage[new_id]
      end

      raise RuntimeException.new("Failed to generate unique session ID")
    end
  end
end
