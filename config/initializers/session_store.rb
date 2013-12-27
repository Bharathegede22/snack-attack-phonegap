# Be sure to restart your server when you modify this file.
Web::Application.config.session_store :cookie_store, key: '_zoomcar_session', :domain => "." + HOSTNAME.gsub("www.", '')
