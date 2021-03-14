require "./spec_helper"

describe HTTPSession do
  it ".new" do
    time = Time.utc
    session = HTTPSession.new("12345")
    session.session_id.should eq "12345"
    session.session_created_at.should be_close(time, 1.second)
    session.session_touched_at.should be_close(time, 1.second)
  end

  it ".valid?" do
    session = HTTPSession.new("12345")
    time = Time.utc
    session.valid?(time).should be_false
    session.touch
    session.valid?(time).should be_true
  end

  it "#touch" do
    session = HTTPSession.new("12345")
    session.session_touched_at.should eq session.session_created_at
    session.touch
    session.session_touched_at.should be > session.session_created_at
  end
end
