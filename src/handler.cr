require "log"
require "http"

# `HTTPSession::Handler` implements `HTTP::Handler` for use with an `HTTP::Server`.
#
# The handler is responsible for populating the `session` property on
# `HTTP::Server::Context`. It does so lazily, i.e. on the first access.
#
# It either loads an existing session from the session store (identified by
# session cookie) or creates a new session.
#
# An `HTTPSession::Storage` instance is used as backend for session storage.
class HTTPSession
  class Handler
    include HTTP::Handler

    # Random source for generating session IDs.
    property random : Random = Random.new

    # Configures the basic properties of the cookie used for
    # communicating the session id to the client.
    getter cookie_prototype : HTTP::Cookie

    # Returns the storage engine.
    getter storage : Storage

    # Creates a new session handler.
    #
    # *cookie_prototype* configures the basic properties of the cookie used for
    # communicating the session id to the client.
    def initialize(@storage : Storage, @cookie_prototype = HTTP::Cookie.new("session_id", ""))
    end

    # Returns the name of the cookie used to communicate the session id to the
    # client.
    #
    # This value is configurable through `cookie_prototype`.
    def cookie_name
      cookie_prototype.name
    end

    def call(context : HTTP::Server::Context)
      context.session_manager = self

      call_next(context)
    end

    # Terminates the session associated with the context.
    #
    # Removes the session cookie and deletes the session from storage.
    def terminate_session(context : HTTP::Server::Context, session_id : String? = nil) : Nil
      session_id ||= context.session?.try(&.session_id) || session_id(context)

      if session_id
        storage.delete(session_id)
        context.response.cookies.delete(cookie_name)
      end
    end

    def initialize_session(context)
      retrieve_session(context) || create_session(context)
    end

    private def session_id(context)
      context.request.cookies[cookie_name]?.try(&.value)
    end

    def retrieve_session(context)
      if session_id = session_id(context)
        if session = storage[session_id]
          session.touch
          session
        end
      end
    end

    private def new_session_id
      random.urlsafe_base64
    end

    def create_session(context)
      session = storage.new_session(new_session_id)

      cookie = cookie_prototype.dup
      cookie.value = session.session_id
      context.response.cookies << cookie

      session
    end
  end

  class HTTP::Server::Context
    @session : HTTPSession?

    property! session_manager : HTTPSession::Handler

    # Returns the session instance associated with this context.
    #
    # It delegates to `session_manager` which tries to retrieve a session as
    # indicated by the session cookie or initializes a new session if that fails.
    def session : HTTPSession
      @session ||= session_manager.initialize_session(self)
    end

    # Returns the session instance associated with this context, but does not
    # create a new session if none exists.
    #
    # It delegates to `session_manager` which tries to retrieve a session as
    # indicated by the session cookie.
    #
    # NOTE: If `session` was called before, the session might actually be freshly
    # initialized but it is still returned because it's already cached in the context.
    def session? : HTTPSession?
      @session ||= session_manager.retrieve_session(self)
    end

    # Terminates the session associated with this context.
    #
    # Removes the session cookie and deletes the session from storage.
    def terminate_session
      session_manager.terminate_session(self)
    end
  end
end
