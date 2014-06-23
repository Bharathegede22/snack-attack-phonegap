Web::Application.routes.draw do
	
	root to: "main#index"
	require 'sidekiq/web'
	

		devise_for :users, 
		:controllers => {
			:confirmations => "users/confirmations", 
			:omniauth_callbacks => "users/omniauth", 
			:passwords => "users/passwords", 
			:registrations => "users/registrations", 
			:sessions => "users/sessions"
		}
	scope "/(:city)", constraints: {city: /Bangalore|Pune/} do
		get '/' => "main#index"
		get '/search' => "bookings#search"
		post '/search/:id' => "bookings#search"

		resources :abtest do
			collection do
				get 'homepage'
				get 'homepagealt'
			end
		end

		if Rails.env == 'production'
			authenticate :user, lambda { |u| u.admin? } do
				mount Sidekiq::Web => '/sidekiq'
			end
		else
			mount Sidekiq::Web => '/sidekiq'
		end

		resources :bookings do
			collection do
				get 'checkout'
				get 'checkoutab'
				get 'complete'
				get 'details'
				get 'do'
				get 'docreate'
				get 'docreatenotify'
				get 'donotify'
				get 'failed'
				get 'license'
				get 'login'
				get 'notify'
				get 'payment'
				get 'payu'
				get 'timeline'
				get 'thanks'
				get 'userdetails'
				get 'widget'

				post 'license'
				post 'payu'
				post 'promo'
				post 'credits'
			end
			member do
				get 'cancel'
				get 'dopayment'
				get 'invoice'
				get 'payments'
				get 'payment'
				get 'reschedule'

				get 'feedback'
				post 'feedback'

				post 'cancel'
				post 'reschedule'
			end
		end

	#as :user do
	#	get 'signin' => 'users#signin', :as => :new_user_session
	#	post 'signin' => 'users#signin', :as => :user_session
	#end

	resources :users do
		collection do
			get 'forgot'
			get 'license'
			get 'password'
			get 'settings'
			get 'social'
			get 'signin'
			get 'signup'
			get 'status'
			get 'credits'

			post 'license'
			post 'signup'
			post 'update'
		end
	end
end
	
	post '/:city/calculator/:id' => 'main#calculator', constraints: {city: /Bangalore|Pune/}
	
	#get '/:city' => 'main#city', constraints: {city: /bangalore|pune/}
	get '/:city/offers' => 'main#offers', constraints: {city: /(Bangalore|Pune)/}
	get '/:city/explore' => 'seo#explore', constraints: {city: /(Bangalore|Pune)/}
	get '/:city/nearby' => 'seo#nearby', constraints: {city: /Bangalore|Pune/}
	#get '/:city/:id' => 'seo#index', constraints: {city: /bangalore|pune/}
	get '/:city/tariff'=>'main#tariff', constraints: {city: /Bangalore|Pune/}
	get '/:city/safety'=>'main#safety', constraints: {city: /Bangalore|Pune/}
	get '/:city/safety'=>'main#safety', constraints: {city: /Bangalore|Pune/}
	get '/:city/calculator/:id'=>'main#calculator', constraints: {city: /Bangalore|Pune/}
	get '/:city/howtozoom'=>'main#howtozoom', constraints: {city: /Bangalore|Pune/}
	get '/:city/outstation'=>'main#outstation', constraints: {city: /Bangalore|Pune/}
	get '/:city/reva'=>'main#reva', constraints: {city: /Bangalore|Pune/}
	get '/:city/faq'=>'main#faq', constraints: {city: /Bangalore|Pune/}
	get '/:city/handover'=>'main#handover', constraints: {city: /Bangalore|Pune/}
	get '/:city/fees'=>'main#fees', constraints: {city: /Bangalore|Pune/}
	get '/:city/eligibility'=>'main#eligibility', constraints: {city: /Bangalore|Pune/}
	get '/:city/member'=>'main#member', constraints: {city: /Bangalore|Pune/}
	get '/:city/privacy'=>'main#privacy', constraints: {city: /Bangalore|Pune/}
	get '/:city/faq'=>'main#faq', constraints: {city: /Bangalore|Pune/}
	# get 'job/:id' => 'main#job'
 #  get ':action(.:format)' => 'main'
 #  get ':action/:id' => 'main'
 #  get ':action' => 'main'
  
end
