require "log"
require "http"

# `HTTP::Session::Handler` implement `HTTP::Handler` for use with an `HTTP::Server`.
#
# The handler sets the `session` property on `HTTP::Server::Context`
# which can then be accessed in subsequent handlers.
# It either loads an existing session from the session store (identified by
# session cookie) or initializes a new session.
#
# An `HTTP::Session::Storage` instance is used as backend for session storage.
class HTTP::Session::Handler
  include HTTP::Handler

  # `random` is uses for generating session IDs.
  property random = Random.new

  getter base_cookie

  # Initializes a new session handler with *storage* backend.
  #
  # *base_cookie* is used to configure the basic properties of the cookie used for
  # communicating the session id to the client.
  def initialize(@storage : Storage, @base_cookie = HTTP::Cookie.new("session_id", ""))
  end

  def cookie_name
    base_cookie.name
  end

  def call(context : HTTP::Server::Context)
    session_item = initialize_session(context)

    call_next(context)

    persist_session(context, session_item)
  end

  def terminate_session(context : HTTP::Server::Context, session_id : String? = nil) : Nil
    session_id ||= context.session?.try(&.session_id) || session_id(context)

    if session_id
      @storage.delete(session_id)
      context.response.cookies.delete(cookie_name)
    end
  end

  def initialize_session(context)
    context.session = retrieve_session(context) || create_session(context)
  end

  private def session_id(context)
    context.request.cookies[cookie_name]?.try(&.value)
  end

  private def retrieve_session(context)
    if session_id = session_id(context)
      if session = @storage[session_id]
        session.touch
        session
      end
    end
  end

  private def create_session(context)
    session = @storage.new_session(random.urlsafe_base64)

    cookie = base_cookie.dup
    cookie.value = session.session_id
    context.response.cookies << cookie

    session
  end

  private def persist_session(context, session_item)
    @storage.persist(session_item)
  end
end

class HTTP::Server::Context
  property! session : Session
end
