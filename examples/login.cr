require "../src/http-session"

class HTTP::Session
  property username : String?
end

session_handler = HTTP::Session::Handler.new(HTTP::Session::Storage::Memory.new)

server = HTTP::Server.new([HTTP::LogHandler.new, HTTP::ErrorHandler.new, session_handler]) do |context|
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
      context.session.username = username
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
      context.terminate_session
      context.response.headers["Location"] = "/"
      context.response.status = :found
    else
      context.response.respond_with_status :method_not_allowed
    end
  when "/"
    if username = context.session?.try(&.username)
      context.response.headers["Content-Type"] = "text/html"
      context.response.puts "Hello #{username}"
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
