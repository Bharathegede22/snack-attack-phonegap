configurations = YAML.load(File.read(File.join(::Rails.root.to_s, 'config', 'configurations.yml')))

FACEBOOK_ID = configurations['facebook_id']
FACEBOOK_SECRET = configurations['facebook_secret']

GOOGLE_ID = configurations['google_id']
GOOGLE_SECRET = configurations['google_secret']
GOOGLE_MAP_KEY = "#{configurations['google_map_api_key']}"

PAYU_API = configurations['payu_api']
PAYU_URL = configurations['payu_url']
PAYU_KEY = configurations['payu_key']
PAYU_SALT = configurations['payu_salt']

AWS_SES_ID = configurations['aws_ses_id']
AWS_SES_KEY = configurations['aws_ses_key']

VARNISH_HOST = configurations['varnish_host']
VARNISH_PORT = configurations['varnish_port']

EXOTEL_SID = configurations['exotel_sid']
EXOTEL_TOKEN = configurations['exotel_token']

SIDEKIQ_CLIENT = configurations['sidekiq_client']
SIDEKIQ_SERVER = configurations['sidekiq_server']
SIDEKIQ_NAMESPACE = configurations['sidekiq_namespace']
