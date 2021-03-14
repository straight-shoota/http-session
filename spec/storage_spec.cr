require "./spec_helper"

describe HTTPSession::Storage do
  it "#new_session" do
    storage = HTTPSession::Storage::Memory.new
    session = storage.new_session("12345")
    session.session_id.should eq "12345"
    storage["12345"].should be(session)
  end

  it "#[]?" do
    storage = HTTPSession::Storage::Memory.new
    session = storage.new_session("12345")
    time = Time.utc
    storage["12345"].should be(session)
    storage.max_age = Time.utc - time
    storage["12345"].should be_nil
    session.touch
    storage.max_age = Time.utc - time
    storage["12345"].should be(session)
  end
end
