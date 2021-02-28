require "spec"
require "../src/http-session"

def handle_http_request(handler, request, ignore_body = false, decompress = true)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call context
  response.close
  io.rewind
  HTTP::Client::Response.from_io(io, ignore_body, decompress)
end

def empty_context(manager)
  HTTP::Server::Context.new(HTTP::Request.new("GET", "/"), HTTP::Server::Response.new(IO::Memory.new)).tap do |context|
    context.session_manager = manager
  end
end
