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

The basic tool for session management is `HTTPSession::Manager`.

The session manager uses a `HTTPSession::Storage` backend for storage.

Currently available implementations:

* `HTTPSession::Storage::Memory`: In-memory storage. Won't persist beyond
  server restarts.

### Example

```crystal
require "http-session"

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
```

More examples can be found in [`examples/`](examples).

## Contributing

1. Fork it (<https://github.com/straight-shoota/http-session/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Johannes Müller](https://github.com/straight-shoota) - creator and maintainer
