require "http"
require "./entry"
require "./storage"

class HTTPSession
  class Manager(T)
    # Random source for generating session IDs.
    property random : Random = Random.new

    # Configures the basic properties of the cookie used for
    # communicating the session id to the client.
    getter cookie_prototype : HTTP::Cookie

    # Returns the storage engine.
    getter storage : Storage(T)

    # Creates a new session handler.
    #
    # *cookie_prototype* configures the basic properties of the cookie used for
    # communicating the session id to the client.
    def initialize(@storage : Storage(T), @cookie_prototype = HTTP::Cookie.new("session_id", ""))
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
      unless session_id = session_id(context)
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
      random.urlsafe_base64
    end
  end
end
