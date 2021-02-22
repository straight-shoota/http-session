require "./spec_helper"

private def dummy_context
  HTTP::Server::Context.new(HTTP::Request.new("GET", "/"), HTTP::Server::Response.new(IO::Memory.new))
end

describe HTTP::Session::Storage do
  it "#new_session" do
    storage = HTTP::Session::Storage::Memory.new
    session = storage.new_session("12345", dummy_context)
    session.session_id.should eq "12345"
    storage["12345"].should be(session)
  end

  it "#[]?" do
    storage = HTTP::Session::Storage::Memory.new
    session = storage.new_session("12345", dummy_context)
    time = Time.utc
    storage["12345"].should be(session)
    storage.max_age = Time.utc - time
    storage["12345"].should be_nil
    session.touch
    storage.max_age = Time.utc - time
    storage["12345"].should be(session)
  end
end
