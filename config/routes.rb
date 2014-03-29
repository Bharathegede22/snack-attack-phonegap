Web::Application.routes.draw do
	
	root to: "main#index"
	
	devise_for :users, 
		:controllers => {
			:confirmations => "users/confirmations", 
			:omniauth_callbacks => "users/omniauth", 
			:passwords => "users/passwords", 
			:registrations => "users/registrations", 
			:sessions => "users/sessions"
		}
	
	get '/search' => "bookings#search"
	post '/search/:id' => "bookings#search"
	
	resources :abtest do
		collection do
			get 'homepage'
			get 'homepagealt'
		end
	end
	
	resources :bookings do
		collection do
			get 'checkout'
			get 'complete'
			get 'details'
			get 'do'
			get 'docreate'
			get 'failed'
			get 'license'
			get 'login'
			get 'payment'
			get 'payu'
			get 'timeline'
			get 'thanks'
			get 'widget'
			
			post 'create_feedback'
			post 'license'
			post 'payu'
			post 'promo'
		end
		member do
			get 'cancel'
			get 'dopayment'
			get 'invoice'
			get 'payments'
			get 'reschedule'
			get 'new_feedback'
			get 'show_feedback'
			
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
			
			post 'license'
			post 'signup'
			post 'update'
		end
	end
	
	post 'calculator/:id' => 'main#calculator'
	
	get '/:city' => 'main#city', constraints: {city: /bangalore/}
	get '/:city/offers' => 'main#offers', constraints: {city: /bangalore/}
	get '/:city/explore' => 'seo#explore', constraints: {city: /bangalore/}
	get '/:city/nearby' => 'seo#nearby', constraints: {city: /bangalore/}
	get '/:city/:id' => 'seo#index', constraints: {city: /bangalore/}
	
	get 'job/:id' => 'main#job'
  get ':action(.:format)' => 'main'
  get ':action/:id' => 'main'
  get ':action' => 'main'
  
end
