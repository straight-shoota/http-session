[![Build Status](https://github.com/straight-shoota/http-session/actions/workflows/ci.yml/badge.svg?branch=master&event=push)](https://github.com/straight-shoota/http-session/actions/workflows/ci.yml)

# `http-session`

This shard provides type-safe sessions for `HTTP::Server`.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     http-session:
       github: straight-shoota/http-session
   ```

2. Run `shards install`

## Usage

To setup session handling, an instance of `HTTP::Session::Handler` needs to be
in the handler chain of the `HTTP::Server` instance. It should come before any
handler that requires access to the session. The session instance
is available through the `session` property of `HTTP::Server::Context`.
`HTTP::Session` can be re-opened to add custom properties.

```crystal
require "http-session"

class HTTP::Session
  property example_counter = 0
end

session_handler = HTTP::Session::Handler.new(HTTP::Session::Storage::Memory.new)

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
```

The session handler uses a `HTTP::Session::Storage` backend for storage.

Currently available implementations:

* `HTTP::Session::Storage::Memory`: In-memory storage. Won't persist beyond
  server restarts.

## Contributing

1. Fork it (<https://github.com/straight-shoota/http-session/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Johannes Müller](https://github.com/straight-shoota) - creator and maintainer
