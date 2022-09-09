require "spec"
require "../../src/storage"

private class TestSession
end

describe HTTPSession::Storage::Memory do
  it "#fetch" do
    storage = HTTPSession::Storage::Memory(TestSession).new
    session1 = TestSession.new
    session2 = TestSession.new
    storage.put("12345", HTTPSession::Storage::Entry.new(session1))
    storage.put("67890", HTTPSession::Storage::Entry.new(session2))
    storage.fetch("12345").try(&.value).should be(session1)
    storage.fetch("67890").try(&.value).should be(session2)
    storage.fetch("54321").should be_nil
  end

  it "#delete_expired" do
    storage = HTTPSession::Storage::Memory(TestSession).new
    session1 = TestSession.new
    storage.put("12345", HTTPSession::Storage::Entry.new(session1))
    time = Time.utc
    sleep 1.microsecond
    session2 = TestSession.new
    storage.put("67890", HTTPSession::Storage::Entry.new(session2))
    storage.delete_expired(time)
    storage.fetch("67890").try(&.value).should be(session2)
    storage.fetch("12345").should be_nil
  end
end
