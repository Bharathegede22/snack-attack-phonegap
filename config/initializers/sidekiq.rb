require 'sidekiq'

Sidekiq.configure_server do |config|
	config.redis = { :url => "redis://#{SIDEKIQ_SERVER}/12", :namespace => SIDEKIQ_NAMESPACE}
end

Sidekiq.configure_client do |config|
	config.redis = { :url => "redis://#{SIDEKIQ_CLIENT}/12", :namespace => SIDEKIQ_NAMESPACE}
	config.client_middleware do |chain|
		# chain.add Sidekiq::Status::ClientMiddleware
	end
end
