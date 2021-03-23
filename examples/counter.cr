require "../src/http-session"

storage = HTTPSession::Storage::Memory(Int32).new
sessions = HTTPSession::Manager.new(storage)

server = HTTP::Server.new([HTTP::LogHandler.new, HTTP::ErrorHandler.new]) do |context|
  if context.request.path == "/"
    counter = sessions.get(context) || 0
    counter += 1
    sessions.set(context, counter)
    context.response.puts counter
  else
    context.response.respond_with_status :not_found
  end
end

address = server.bind_tcp 0
puts "Listening on http://#{address}"

server.listen
