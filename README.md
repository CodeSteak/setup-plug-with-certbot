# Setup Plug With Certbot

This is a small piece of code that automatically generates and renews (letsencrypt) certs
using Certbot.

You could probably implement it your self, but maybe it is useful.

## Does renewing actually work?

~~I guess I have to wait 60 Days to find out :/.~~
Works for me! :D

### Including it in your code

Add this repository to your deps:
```elixir
def deps do
  [
      {:certbot, git: "https://github.com/CodeSteak/setup-plug-with-certbot", tag: "0.0.1-certbot"}
  ]
end
```

### Configure

For configuration see `config/example_config.exs`.

Certs will be generated in
```elixir
    [maindomain|_] = Application.fetch_env!(:certbot, :domains)

    keyfiles_prefix = Path.join([Application.fetch_env!(:certbot, :config_dir), "live", maindomain])

    https_cert_opts = [
        keyfile: Path.join(keyfiles_prefix, "privkey.pem"),
        cacertfile: Path.join(keyfiles_prefix, "chain.pem"),
        certfile: Path.join(keyfiles_prefix, "cert.pem"),
    ]
```
Append `https_cert_opts` to your https_opts.

### Add Hooks In Your Code

Add a Certbot Worker to your http Supervisor:
```elixir
def my_workers() do
    [
     # other workers
        {Certbot,
            worker: [
                {Plug.Adapters.Cowboy2,
                      scheme: :https,
                      plug: Server.Router,
                      options: <YOUR HTTPS OPTIONS>}
            ]
        },
    ]
end
```
This library will start every worker supplied in `worker:` as soon as
the Certificates are ready.

You want to put something like this in your Plug Main Router:
```elixir
defmodule MyServer.Router do
  use Plug.Router


  plug(Certbot.Plug, [])

  if Application.fetch_env!(:myserver, :use_https) do
    plug(Plug.SSL)
  end

  # rest of the stuff
  # ...
end
```

Now you should be ready.

---

Feel free to open issues if you have questions.

---
[Codesteak](https://github.com/CodeSteak/setup-plug-with-certbot/)
