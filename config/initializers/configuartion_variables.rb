configurations = YAML.load(File.read(File.join(::Rails.root.to_s, 'config', 'configurations.yml')))
HOSTNAME = configurations['hostname']

FACEBOOK_ID = configurations['facebook_id']
FACEBOOK_SECRET = configurations['facebook_secret']

GOOGLE_ID = configurations['google_id']
GOOGLE_SECRET = configurations['google_secret']
GOOGLE_MAP_KEY = "#{configurations['google_map_api_key']}"

PAYU_URL = configurations['payu_url']
PAYU_KEY = configurations['payu_key']
PAYU_SALT = configurations['payu_salt']
