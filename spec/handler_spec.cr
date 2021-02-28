require "./spec_helper"

private def empty_context(manager)
  HTTP::Server::Context.new(HTTP::Request.new("GET", "/"), HTTP::Server::Response.new(IO::Memory.new)).tap do |context|
    context.session_manager = manager
  end
end

describe HTTP::Session::Handler do
  describe "#call" do
    it "initializes session" do
      storage = HTTP::Session::Storage::Memory.new
      handler = HTTP::Session::Handler.new(storage)
      handler.next = ->(context : HTTP::Server::Context) do
        context.response.print "session_id: #{context.session.session_id}"
      end
      handler.random = Random.new(1)

      request = HTTP::Request.new("GET", "/")
      response = handle_http_request(handler, request)
      cookie = response.cookies["session_id"]
      cookie.value.should eq "UTA54jUvEQE1nVDTSi-TCw"
      response.body.should eq "session_id: UTA54jUvEQE1nVDTSi-TCw"

      request = HTTP::Request.new("GET", "/")
      request.cookies << cookie
      response = handle_http_request(handler, request)
      response.body.should eq "session_id: UTA54jUvEQE1nVDTSi-TCw"
    end
  end

  describe "#initialize_session" do
    it "overrides invalid session cookie" do
      storage = HTTP::Session::Storage::Memory.new
      handler = HTTP::Session::Handler.new(storage)
      context = empty_context(handler)
      handler.random = Random.new(1)

      context.request.cookies << HTTP::Cookie.new(handler.cookie_name, "invalid")

      handler.initialize_session(context)
      context.session.session_id.should eq "dmekijYgU4zYIc2g0KjmuA"

      cookie = context.response.cookies["session_id"]
      cookie.value.should eq "dmekijYgU4zYIc2g0KjmuA"
    end
  end

  it "#terminate_session" do
    storage = HTTP::Session::Storage::Memory.new
    handler = HTTP::Session::Handler.new(storage)
    context = empty_context(handler)
    session_id = context.session.session_id
    context.response.cookies["session_id"]?.try(&.value).should eq session_id
    storage[session_id].should be context.session

    handler.terminate_session(context, session_id)

    context.response.cookies.has_key?("session_id").should be_false
    storage[session_id].should be_nil
  end
end
