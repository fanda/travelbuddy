Tb::Application.routes.draw do



  resources :travels, :only => [:new, :create] do
    collection do
      get 'match'
    end
  end

  resources :trips, :except => [:destroy, :edit] do
    member do
      get  'invite_friends', :as => 'invite_users'
      post 'invite_friends'
      put  'join'
      put  'leave'
      put  'reject'
      put  'accept'
    end
    resources :files, :except => [:show, :index, :edit, :update]
    resources :events, :except => [:show, :index]
  end
  match '/trips/:id/:year(/:month)' => 'trips#show', :as => :calendar, :constraints => {:year => /\d{4}/, :month => /\d{1,2}/}
  match '/trips/:trip_id/user/:id/accept' => 'trips#accept_user', :as => :accept_user_trip, :via => :put
  match '/trips/:trip_id/user/:id/deny' => 'trips#deny_user', :as => :deny_user_trip, :via => :put

  root :to => "main#index"

  match "/signin" => "services#signin"
  match "/signout" => "services#signout"

  match '/auth/:service/callback' => 'services#create'
  match '/auth/failure' => 'services#failure'

  resources :services, :only => [:index, :create, :destroy] do
    collection do
      get 'signin'
      get 'signout'
      get 'signup'
      get 'failure'
    end
  end

  match 'user/settings' => 'main#user_settings', :as => 'user_settings'
  match 'user/:uid' => 'main#user_profile', :as => 'user_profile'
  match 'friend/facebook/:uid' => 'facebook#friend_info'
  match 'other-facebook-friends' => 'facebook#not_in_app_friends'

  match 'message/:id' => 'main#message'

  match 'invite_friends' => 'facebook#invite', :as => 'invite_friends'
  match 'share' => 'facebook#share', :as => 'share'

  match 'welcome' => 'facebook#welcome'

end
