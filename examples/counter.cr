require "../src/http-session"

class HTTPSession
  property example_counter = 0
end

session_handler = HTTPSession::Handler.new(HTTPSession::Storage::Memory.new)

server = HTTP::Server.new([HTTP::LogHandler.new, HTTP::ErrorHandler.new, session_handler]) do |context|
  if context.request.path == "/"
    context.session.example_counter += 1
    context.response.puts context.session.example_counter
  else
    context.response.respond_with_status :not_found
  end
end

address = server.bind_tcp 0
puts "Listening on http://#{address}"

server.listen
