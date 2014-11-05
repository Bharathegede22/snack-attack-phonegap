Web::Application.routes.draw do

	get 'mydeposits' => "wallets#show"
  get 'bookings'  => "wallets#show"
	get 'device'  => "main#device"

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

	resources :bookings, :except => [:index, :delete] do
		collection do
			get 'corporate'
			get 'details'
			get 'docreatenotify'
			get 'donotify'
			get 'license'
			get 'notify'
			get 'outstanding'
			get 'payu'
			get 'timeline'
			get 'thanks'
			get 'widget'

			post 'credits'
			post 'corporate'
			post 'license'
			post 'payu'
			post 'promo'
		end
		member do
			get 'dodeposit'
			get 'cancel'
			get 'dopayment'
			get 'invoice'
			get 'payments'
			get 'payment'
			get 'reschedule'
			get 'feedback'
			get 'holddeposit'
			post 'feedback'

			post 'cancel'
			post 'reschedule'
		end
	end
	get '/resume' => 'bookings#resume_booking'

	resources :users do
		collection do
			get 'access'
			get 'credits'
			get 'forgot'
			get 'license'
			get 'license_get_del'
			get 'password'
			get 'settings'
			get 'social'
			get 'signin'
			get 'signup'
			get 'status'
			get 'status_old'

			post 'license'
			post 'license_get_del'
			post 'signup'
			post 'update'
		end
	end

	resources :wallets, :only => [] do
		collection do
			get 'history'
  		get 'show_refund'
      get 'credit_history'
			#post "wallets#topup"
  		post 'refund'
  		post 'topup'
		end
	end
	
	scope "/(:city)", constraints: {city: /bangalore|pune/} do
		resources :bookings do
			collection do
				get 'checkout'
				get 'checkoutab'
				get 'complete'
				get 'do'
				get 'docreate'
				post 'docreate'
				get 'failed'
				get 'login'
				get 'payment'
				get 'userdetails'
			end
		end
	end

	post '/calculator/:id' => 'main#calculator'
	get '/calculator/:id' => 'main#calculator'
	
	get '/job/:id' => 'main#job'
	get '/get_locations_map/:id' => 'main#get_locations_map'
 	get ':action' => 'main', constraints: {action: /about|careers|contact|eligibility|handover|holidays|howitworks|signup|howtozoom|map|member|outstation|reva|privacy|mobile_redirect/}
 	
 	# Redirect
 	get ':id' => 'main#redirect', constraints: {id: /join|login|mybookings|myaccount|selfdrivecarrental/}
 	get '/jsi/:key/:id' => 'main#redirect'
 	get ':city/:id' => 'main#redirect', constraints: {city: /Pune|Bangalore/}
 	
	scope "/(:city)", constraints: {city: /bangalore|pune/} do
		post '/search/:id' => 'bookings#search'
		get '/search' => 'bookings#search'
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
