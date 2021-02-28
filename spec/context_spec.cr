require "./spec_helper"

describe HTTP::Server::Context do
  it "#session" do
    storage = HTTP::Session::Storage::Memory.new
    handler = HTTP::Session::Handler.new(storage)
    handler.random = Random.new(1)
    context = empty_context(handler)

    session = context.session

    session_id = session.session_id
    storage[session_id].should be session
    session_id.should eq "UTA54jUvEQE1nVDTSi-TCw"

    context.response.cookies["session_id"]?.try(&.value).should eq session_id
  end

  it "#session?" do
    storage = HTTP::Session::Storage::Memory.new
    handler = HTTP::Session::Handler.new(storage)
    context = empty_context(handler)

    context.session?.should be_nil
    context.response.cookies.empty?.should be_true
    storage.@storage.empty?.should be_true

    session = context.session

    context.session?.should be session
  end
end
