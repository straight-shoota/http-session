require "../spec_helper"

describe HTTP::Session::Storage::Memory do
  it "#fetch" do
    storage = HTTP::Session::Storage::Memory.new
    session1 = HTTP::Session.new("12345")
    session2 = HTTP::Session.new("67890")
    storage.put(session1)
    storage.put(session2)
    storage.fetch("12345").should be(session1)
    storage.fetch("67890").should be(session2)
    storage.fetch("54321").should be_nil
  end

  it "#delete_expired" do
    storage = HTTP::Session::Storage::Memory.new
    session1 = HTTP::Session.new("12345")
    storage.put(session1)
    time = Time.utc
    sleep 1.microsecond
    session2 = HTTP::Session.new("67890")
    storage.put(session2)
    storage.delete_expired(time)
    storage.fetch("67890").should be(session2)
    storage.fetch("12345").should be_nil
  end
end
