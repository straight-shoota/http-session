require "spec"
require "../src/storage"

describe HTTPSession::Storage do
  it "#[]" do
    storage = HTTPSession::Storage::Memory(String).new
    session = "session_object"
    entry = HTTPSession::Storage::Entry.new(session)
    storage.put("12345", entry)
    time = Time.utc
    storage["12345"].should be(session)
    storage.max_age = Time.utc - time
    storage["12345"].should be_nil
  end
end
