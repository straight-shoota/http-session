require "spec"
require "../src/entry"

describe HTTPSession::Entry do
  it ".new" do
    time = Time.utc
    entry = HTTPSession::Entry.new("12345")
    entry.value.should eq "12345"
    entry.created_at.should be_close(time, 1.second)
    entry.touched_at.should be_close(time, 1.second)
  end

  it ".valid?" do
    entry = HTTPSession::Entry.new("12345")
    time = Time.utc
    entry.valid?(time).should be_false
    entry.touch
    entry.valid?(time).should be_true
  end

  it "#touch" do
    entry = HTTPSession::Entry.new("12345")
    entry.touched_at.should eq entry.created_at
    entry.touch
    entry.touched_at.should be > entry.created_at
  end
end
