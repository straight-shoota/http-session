require "./spec_helper"

describe HTTP::Session::Handler do
  it "sets session cookie" do
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

  it "initializes session lazily" do
    storage = HTTP::Session::Storage::Memory.new
    handler = HTTP::Session::Handler.new(storage)
    handler.next = ->(context : HTTP::Server::Context) do
      context.response.puts "session_id: #{context.session?.try(&.session_id) || "nil"}"
      context.response.puts "cookies: #{context.response.cookies.size}"
      context.response.puts "session_id: #{context.session.session_id}"
      context.response.print "cookies: #{context.response.cookies.size}"
    end
    handler.random = Random.new(1)

    request = HTTP::Request.new("GET", "/")
    response = handle_http_request(handler, request)
    cookie = response.cookies["session_id"]
    cookie.value.should eq "UTA54jUvEQE1nVDTSi-TCw"
    response.body.should eq <<-TXT
      session_id: nil
      cookies: 0
      session_id: UTA54jUvEQE1nVDTSi-TCw
      cookies: 1
      TXT

    request = HTTP::Request.new("GET", "/")
    request.cookies << cookie
    response = handle_http_request(handler, request)
    response.body.should eq <<-TXT
      session_id: nil
      cookies: 0
      session_id: UTA54jUvEQE1nVDTSi-TCw
      cookies: 0
      TXT
  end

  it "overrides invalid session cookie" do
    storage = HTTP::Session::Storage::Memory.new
    handler = HTTP::Session::Handler.new(storage)
    handler.next = ->(context : HTTP::Server::Context) do
      context.response.print "session_id: #{context.session.session_id}"
    end
    handler.random = Random.new(1)

    request = HTTP::Request.new("GET", "/")
    request.cookies << handler.cookie_prototype.dup.tap do |request_cookie|
      request_cookie.value = "invalid"
    end
    response = handle_http_request(handler, request)
    cookie = response.cookies["session_id"]
    cookie.value.should eq "UTA54jUvEQE1nVDTSi-TCw"
    response.body.should eq "session_id: UTA54jUvEQE1nVDTSi-TCw"
  end

  it "#terminate_session" do
    storage = HTTP::Session::Storage::Memory.new
    handler = HTTP::Session::Handler.new(storage)
    handler.next = ->(context : HTTP::Server::Context) do
      session_id = context.session.session_id
      handler.terminate_session(context, session_id)
      context.response.print "Deleted session_id: #{session_id}"
    end
    handler.random = Random.new(1)

    request = HTTP::Request.new("GET", "/")
    response = handle_http_request(handler, request)
    cookie = response.cookies.has_key?("session_id").should be_false
    response.body.should eq "Deleted session_id: UTA54jUvEQE1nVDTSi-TCw"
    storage["UTA54jUvEQE1nVDTSi-TCw"].should be_nil
  end
end
