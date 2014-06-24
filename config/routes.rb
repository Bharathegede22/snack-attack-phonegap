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
			
			post 'corporate'
			post 'credits'
			post 'license'
			post 'payu'
			post 'promo'
		end
		member do
			get 'cancel'
			get 'dopayment'
			get 'feedback'
			get 'invoice'
			get 'payments'
			get 'payment'
			get 'reschedule'
			
			post 'cancel'
			post 'feedback'
			post 'reschedule'
		end
	end

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
	
	scope "/(:city)", constraints: {city: /bangalore|pune/} do
		get '/' => 'main#index'
		get '/attractions' => 'main#city'
		get '/offers' => 'main#offers'
		get '/attractions' => 'seo#index'
		get '/explore' => 'seo#explore'
		get '/nearby' => 'seo#nearby'
		get '/tariff'=>'main#tariff'
		get '/safety'=>'main#safety'
		get '/fees'=>'main#fees'
		get '/:id' => 'seo#index'
	end
	
	post 'calculator/:id' => 'main#calculator'
	get 'job/:id' => 'main#job'
 	get ':action(.:format)' => 'main'
	get ':action/:id' => 'main'
	get ':action' => 'main'
  
end
