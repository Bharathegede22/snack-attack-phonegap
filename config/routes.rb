Web::Application.routes.draw do
	get 'mydeposits' => "wallets#show"
  	get 'bookings'  => "wallets#show"
	get 'device'  => "main#device"
	get 'deals' => "main#deals_of_the_day"
	scope "/(:city)", constraints: {city: /bangalore|delhi|pune/} do
		get 'bookings/do_flash_booking' => 'bookings#do_flash_booking'
	end

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
			get 'pgresponse'
			get 'timeline'
			get 'thanks'
			get 'widget'
			get 'seamless_payment_options'

			post 'credits'
			post 'corporate'
			post 'license'
			post 'payu'
			post 'pgresponse'
			post 'promo'
			post 'seamless_update_payment'
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
			post 'seamless_dodeposit'
			post 'seamless_dopayment'
			post 'reschedule'
		end
	end
	get '/resume' => 'bookings#resume_booking'

	resources :users do
		collection do
			get 'access'
			get 'credit_history'
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
  		post 'refund'
  		post 'topup'
		end
	end
	
	scope "/(:city)", constraints: {city: /bangalore|delhi|pune/} do
		resources :bookings do
			collection do
				get 'checkout'
				get 'checkoutab'
				get 'complete'
				get 'do'
				# get 'do_flash_booking'
				get 'docreate'
				post 'docreate'
				get 'failed'
				get 'login'
				get 'payment'
				get 'userdetails'
				post 'seamless_docreate'
			end
		end
	end

	post '/calculator/:id' => 'main#calculator'
	get '/calculator/:id' => 'main#calculator'
	
	get '/job/:id' => 'main#job'
	get '/get_locations_map/:id' => 'main#get_locations_map'
 	get ':action' => 'main', constraints: {action: /about|careers|eligibility|handover|holidays|howitworks|signup|howtozoom|map|member|outstation|reva|privacy|mobile_redirect/}
 	
 	# Redirect
 	get ':id' => 'main#redirect', constraints: {id: /contact|join|login|mybookings|myaccount|selfdrivecarrental/}
 	get '/jsi/:key/:id' => 'main#redirect'
 	get ':city/:id' => 'main#redirect', constraints: {city: /Pune|Bangalore/}
 	
	scope "/(:city)", constraints: {city: /bangalore|delhi|pune/} do
		post '/search/:id' => 'bookings#search'
		get '/search' => 'bookings#search'
		get '/' => 'main#index'
		get '/attractions' => 'main#city'
		get '/explore' => 'seo#explore'
		get '/faq'=>'main#faq'
		get '/fees'=>'main#fees'
		get '/contact'=>'main#contact'
		get '/offers' => 'main#offers'
		get '/nearby' => 'seo#nearby'
		get '/tariff'=>'main#tariff'
		get '/safety'=>'main#safety'
		get '/:id' => 'seo#index'
	end

end
