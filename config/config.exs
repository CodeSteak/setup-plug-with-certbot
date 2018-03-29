# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :webserver, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:webserver, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

use_https = Mix.env() == :prod

# list of domain the cert will be created for

# !!! change me
domains = ["example.com", "www.example.com"]

# ??? change me
certs_dir = Path.absname("data/certs")
# ??? change me
www_dir = Path.absname("data/www")
# ??? change me
utils_dir = Path.absname("data/utils")

keyfiles_prefix = Path.join([certs_dir, "config", "live", List.first(domains)])

# !!! change me
notification_email = "human@example.com"

# https://letsencrypt.org/repository/
# use :yes to agree
# ??? change me
agree_letsencrypt_tos = :no
# Share your e-mail address with EFF
# ??? change me
eff_email = false

# You may want to test it once.
# When this is true the letsencrypt staging server
# is used to create a certificate for a fake ca.
# See: https://letsencrypt.org/docs/staging-environment/
certbot_testing = true

# See README.md on ports
port_http = 4000
port_https = 4443

config :webserver,
  http_opts: [
    {:port, port_http},
    :inet6,
    {:ip, :any}
  ],
  use_https: use_https,
  https_opts: [
    {:port, port_https},
    :inet6,
    {:ip, :any},
    # Use this ciphers for http/2 (else connection will be rejected)
    ciphers: :ssl.cipher_suites(:default, :"tlsv1.2"),
    keyfile: Path.join(keyfiles_prefix, "/privkey.pem"),
    cacertfile: Path.join(keyfiles_prefix, "/chain.pem"),
    certfile: Path.join(keyfiles_prefix, "/cert.pem")
  ],
  certbot: [
    domains: domains,
    config_dir: Path.join(certs_dir, "/config/"),
    work_dir: Path.join(certs_dir, "/work/"),
    logs_dir: Path.join(certs_dir, "/logs/"),
    www_dir: www_dir,
    email: notification_email,
    agree_tos: agree_letsencrypt_tos,
    testing: certbot_testing,
    eff_email: eff_email
  ],
  certs_dir: certs_dir,
  www_dir: www_dir,
  utils_dir: utils_dir
