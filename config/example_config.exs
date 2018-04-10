use Mix.Config

# list of domain the cert will be created for
domains = ["example.com", "subdomainone.example.com", "two.example.com"]

certs_dir = Path.absname("data/certs")

# In this directory will be written. [acme-challenge]
#
# Every thing in .well-known will
# be served by `Certbot.Plug`
www_dir = Path.absname("data/www")

utils_dir = Path.absname("data/utils")

notification_email = "myemailz@example.com"
# https://letsencrypt.org/repository/
# use :yes to agree
agree_letsencrypt_tos = :no

# Share your e-mail address with EFF
eff_email = false
# You may want to test it once
# When this is true the letsencrypt staging server
# to create a certificate for a fake ca.
# See: https://letsencrypt.org/docs/staging-environment/
certbot_testing = true

config :certbot,
  domains: domains,
  utils_dir: utils_dir,
  config_dir: Path.join(certs_dir, "/config/"),
  work_dir: Path.join(certs_dir, "/work/"),
  logs_dir: Path.join(certs_dir, "/logs/"),
  www_dir: www_dir,
  email: notification_email,
  agree_tos: agree_letsencrypt_tos,
  testing: certbot_testing,
  eff_email: eff_email
