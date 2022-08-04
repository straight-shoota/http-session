require "spec"
require "../src/manager"
require "../src/storage"

private def empty_context
  HTTP::Server::Context.new(HTTP::Request.new("GET", "/"), HTTP::Server::Response.new(IO::Memory.new))
end

private class TestSession
end

describe HTTPSession::Manager do
  describe "#set" do
    it do
      storage = HTTPSession::Storage::Memory(TestSession).new
      manager = HTTPSession::Manager.new(storage)
      manager.random = Random.new(1)
      session = TestSession.new
      context = empty_context
      manager.set(context, session)
      cookie = context.response.cookies["session_id"]
      cookie.value.should eq "UTA54jUvEQE1nVDTSi-TCw"
      storage["UTA54jUvEQE1nVDTSi-TCw"].should be(session)
    end

    it "strict session management (disallow fake session_id)" do
      storage = HTTPSession::Storage::Memory(TestSession).new
      manager = HTTPSession::Manager.new(storage)
      session = TestSession.new

      context = empty_context
      context.request.cookies["session_id"] = "123456"
      manager.set(context, session)

      cookie = context.response.cookies["session_id"]?.should_not be_nil
      cookie.value.should_not eq "123456"
    end
  end

  describe "#delete" do
    it "existing session" do
      storage = HTTPSession::Storage::Memory(TestSession).new
      storage["foobar"] = TestSession.new

      manager = HTTPSession::Manager.new(storage)

      context = empty_context
      context.request.cookies["session_id"] = "foobar"
      manager.delete(context)
      manager.get(context).should be_nil
      storage["foobar"].should be_nil
    end

    it "new session" do
      storage = HTTPSession::Storage::Memory(TestSession).new
      manager = HTTPSession::Manager.new(storage)
      manager.random = Random.new(1)
      session = TestSession.new
      context = empty_context

      manager.set(context, session)

      context.response.cookies["session_id"]?.try(&.value).should eq "UTA54jUvEQE1nVDTSi-TCw"
      storage["UTA54jUvEQE1nVDTSi-TCw"].should be session

      manager.delete(context)
      manager.get(context).should be_nil

      context.response.cookies.has_key?("session_id").should be_false
      storage["UTA54jUvEQE1nVDTSi-TCw"].should be_nil
    end
  end
end
