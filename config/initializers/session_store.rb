# Be sure to restart your server when you modify this file.
if ::Rails.env == 'production'
	Web::Application.config.session_store :cookie_store, key: '_zoom_session', :domain => ".zoomcar.in"
else
	Web::Application.config.session_store :cookie_store, key: '_zoom_session', :domain => ".local.dev"
end
