Web::Application.routes.draw do
	
	devise_for :users, 
		:controllers => {
			:confirmations => "users/confirmations", 
			:omniauth_callbacks => "users/omniauth", 
			:passwords => "users/passwords", 
			:registrations => "users/registrations", 
			:sessions => "users/sessions"
		}
	
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
			get 'corporate'
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

			post 'credits'
			post 'corporate'
			post 'license'
			post 'payu'
			post 'promo'
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
	
	post '/search/:id' => 'bookings#search'
	get '/search' => 'bookings#search'
	
	post '/calculator/:id' => 'main#calculator'
	get '/calculator/:id' => 'main#calculator'
	
	get '/job/:id' => 'main#job'
 	get ':action' => 'main', constraints: {action: /about|careers|contact|eligibility|handover|howitworks|map|member|outstation|reva|privacy/}
 	
	scope "/(:city)", constraints: {city: /bangalore|pune/} do
		get '/' => 'main#index'
		get '/attractions' => 'main#city'
		get '/explore' => 'seo#explore'
		get '/faq'=>'main#faq'
		get '/fees'=>'main#fees'
		get '/offers' => 'main#offers'
		get '/nearby' => 'seo#nearby'
		get '/tariff'=>'main#tariff'
		get '/safety'=>'main#safety'
		get '/:id' => 'seo#index'
	end
  
end
