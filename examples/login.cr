require "../src/http-session"

record UserSession, username : String

storage = HTTPSession::Storage::Memory(UserSession).new
sessions = HTTPSession::Manager.new(storage)

spawn do
  storage.run_gc_loop
end

server = HTTP::Server.new([HTTP::LogHandler.new, HTTP::ErrorHandler.new]) do |context|
  case context.request.path
  when "/login"
    case context.request.method
    when "POST"
      data = URI::Params.parse(context.request.body.try(&.gets_to_end).to_s)
      username = data["username"].strip
      if username.empty?
        context.response.respond_with_status :unauthorized
        next
      end
      Log.info { "authenticated user #{username}" }

      sessions.set(context, UserSession.new(username))

      context.response.headers["Location"] = "/"
      context.response.status = :found
      next
    when "GET"
      context.response.headers["Content-Type"] = "text/html"
      context.response.puts <<-HTML
        <form action="/login" method="POST">
          <label for="username">username</label>
          <input type="text" name="username">
        </form>
        HTML
    when "DELETE"
      sessions.delete(context)
      context.response.headers["Location"] = "/"
      context.response.status = :found
    else
      context.response.respond_with_status :method_not_allowed
    end
  when "/"
    if session = sessions.get(context)
      context.response.headers["Content-Type"] = "text/html"
      context.response.puts "Hello #{session.username}"
      context.response.puts <<-HTML
        <form action="/login" method="DELETE">
          <button type="submit">Logout</button>
        </form>
        HTML
    else
      context.response.headers["Location"] = "/login"
      context.response.status = :found
    end
  else
    context.response.respond_with_status :not_found
  end
end

address = server.bind_tcp 0
puts "Listening on http://#{address}"

server.listen
