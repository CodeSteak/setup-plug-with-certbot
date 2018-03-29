# WARNING: This is not yet sufficiently tested.

# Webserver

This is a template for creating a __plug server__ with __letsencrypt__ certificates. It uses __Certbot__.
The certificates can be created as user (The same as is used for the webserver).

## Setup

Clone this repo and use it as template.

You need to replace the placeholders in `config/config.exs`
with your real data.

run `mix release.init` initialize configure for a 'release'. 'Releases' come handy when using Systemd (see below).
(see also [https://hexdocs.pm/distillery/](https://hexdocs.pm/distillery/)).

### Install Certbot

Install Certbot on your server.

See [https://certbot.eff.org/](https://certbot.eff.org/).

### Use port 80 / 443

You may want to use the following lines to redirect any incomming tcp connections on 80 and 443,
since only root can open these ports on your Server.
You may need to adopt these for your Server OS accordingly.

`/etc/network/interfaces` on `Ubuntu 16.04 xenial`:
```shell
[...]

post-up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 4000
post-up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 4443
post-up ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 4000
post-up ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 4443
```

### Starting

It is best to run the webserver interactively for the first time, so you can see configuration errors immediately.
To run the webserver interactively use:
```
MIX_ENV=prod mix release
```
```
_build/prod/rel/webserver/bin/webserver console
```

### Use Systemd to start your webserver on boot

See
[https://hexdocs.pm/distillery/use-with-systemd.html#content](https://hexdocs.pm/distillery/use-with-systemd.html#content
) for information.
