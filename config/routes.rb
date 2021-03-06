#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'sidekiq/web'

Diaspora::Application.routes.draw do

  post "apiuser_profile/get_profile"
  post "authorize/verify"

  namespace :api do
     resources :contacts, :defaults => { :format => 'json' } do

    end
     resources :aspects, :defaults => { :format => 'json' } do

    end
     resources :users, :defaults => { :format => 'json' } do
	    collection do
	      get 'get_user_contact_list/:diaspora_handle/:access_token' , :action => 'get_user_contact_list', constraints: { diaspora_handle: /[^\/]+/ }
	      get 'get_user_aspects_list/:diaspora_handle/:access_token' , :action => 'get_user_aspects_list' , constraints: { diaspora_handle: /[^\/]+/ }
	      get 'get_user_followed_tags_list/:diaspora_handle/:access_token' , :action => 'get_user_followed_tags_list' , constraints: { diaspora_handle: /[^\/]+/ }
	      get 'get_user_details/:diaspora_handle/:access_token' , :action => 'get_user_details' , constraints: { diaspora_handle: /[^\/]+/ }
	      get 'get_user_contact_handle_list/:diaspora_handle/:access_token' , :action => 'get_user_contact_handle_list' , constraints: { diaspora_handle: /[^\/]+/ }
              get 'get_app_scopes_of_given_user/:id/:diaspora_handle/:access_token' , :action => 'get_app_scopes_of_given_user' , constraints: { diaspora_handle: /[^\/]+/ }
	      post 'edit_email/:access_token' , :action => 'edit_email'
	      post 'edit_first_name/:access_token' , :action => 'edit_first_name'
	      post 'edit_last_name/:access_token' , :action => 'edit_last_name'
	      post 'edit_user_location/:access_token' , :action => 'edit_user_location'
	end
    end
     resources :statusMessages, :defaults => { :format => 'json' } do
	    collection do
	      get 'get_given_user_status_list/:diaspora_handle/:access_token' , :action => 'get_given_user_status_list' , constraints: { diaspora_handle: /[^\/]+/ }
	      get 'get_comments_for_status_message/:id/:diaspora_handle/:access_token' , :action => 'get_comments_for_status_message' , constraints: { diaspora_handle: /[^\/]+/ } 
 	      get 'get_likes_for_status_message/:id/:diaspora_handle/:access_token' , :action => 'get_likes_for_status_message' , constraints: { diaspora_handle: /[^\/]+/ }
 	      get 'get_number_of_comments_for_status_message/:id/:diaspora_handle/:access_token' , :action => 'get_number_of_comments_for_status_message' , constraints: { diaspora_handle: /[^\/]+/ }
 	      post 'create_status_message/:access_token' , :action => 'create_status_message'
 	      delete 'delete_status_message/:access_token' , :action => 'delete_status_message'
	end
    end
     resources :thirdpartyApps, :defaults => { :format => 'json' } do
	    collection do
	      get 'index/:access_token' , :action => 'index'
	      get 'show/:id/:access_token' , :action => 'show'
	    end
    end
    #resources :users, :defaults => { :format => 'json' } do
     resources :comments, :defaults => { :format => 'json' } do
	    collection do
	      get 'get_given_user_comment_list/:diaspora_handle/:access_token' , :action => 'get_given_user_comment_list' , constraints: { diaspora_handle: /[^\/]+/ }
  	      get 'get_likes_count/:id/:diaspora_handle/:access_token' , :action => 'get_likes_count' , constraints: { diaspora_handle: /[^\/]+/ }
	      post 'create_comment/:access_token' , :action => 'create_comment'
	      delete 'delete_comment/:access_token' , :action => 'delete_comment'
	end
    end
  end

  if Rails.env.production?
    mount RailsAdmin::Engine => '/admin_panel', :as => 'rails_admin'
  end

  constraints ->(req) { req.env["warden"].authenticate?(scope: :user) &&
                        req.env['warden'].user.admin? } do
    mount Sidekiq::Web => '/sidekiq', :as => 'sidekiq'
  end

  get "/atom.xml" => redirect('http://blog.diasporafoundation.org/feed/atom') #too many stupid redirects :()

  get 'oembed' => 'posts#oembed', :as => 'oembed'
  # Posting and Reading
  resources :reshares

  resources :status_messages, :only => [:new, :create]

  resources :posts do
    member do
      get :next
      get :previous
      get :interactions
    end

    resources :likes, :only => [:create, :destroy, :index ]
    resources :participations, :only => [:create, :destroy, :index]
    resources :comments, :only => [:new, :create, :destroy, :index]
  end

  get 'p/:id' => 'posts#show', :as => 'short_post'
  get 'posts/:id/iframe' => 'posts#iframe', :as => 'iframe'

  # roll up likes into a nested resource above
  resources :comments, :only => [:create, :destroy] do
    resources :likes, :only => [:create, :destroy, :index]
  end

  # Streams
  get "participate" => "streams#activity", :as => "activity_stream" # legacy
  get "explore" => "streams#multi", :as => "stream"                 # legacy

  get "activity" => "streams#activity", :as => "activity_stream"
  get "stream" => "streams#multi", :as => "stream"
  get "public" => "streams#public", :as => "public_stream"
  get "followed_tags" => "streams#followed_tags", :as => "followed_tags_stream"
  get "mentions" => "streams#mentioned", :as => "mentioned_stream"
  get "liked" => "streams#liked", :as => "liked_stream"
  get "commented" => "streams#commented", :as => "commented_stream"
  get "aspects" => "streams#aspects", :as => "aspects_stream"

  resources :aspects do
    put :toggle_contact_visibility
  end

  get 'bookmarklet' => 'status_messages#bookmarklet'

  resources :photos, :except => [:index] do
    put :make_profile_photo
  end

  # ActivityStreams routes
  scope "/activity_streams", :module => "activity_streams", :as => "activity_streams" do
    resources :photos, :controller => "photos", :only => [:create]
  end

  resources :conversations do
    resources :messages, :only => [:create, :show]
    delete 'visibility' => 'conversation_visibilities#destroy'
  end

  get 'notifications/read_all' => 'notifications#read_all'
  resources :notifications, :only => [:index, :update] do
  end

  resources :tags, :only => [:index]

  resources "tag_followings", :only => [:create, :destroy, :index]

  get 'tags/:name' => 'tags#show', :as => 'tag'

  resources :apps, :only => [:show]

  #Cubbies info page

  resource :token, :only => :show

  # Users and people

  resource :user, :only => [:edit, :update, :destroy], :shallow => true do
    get :getting_started_completed
    get :export
    get :export_photos
  end

  controller :users do
    get 'public/:username'          => :public,           :as => 'users_public'
    match 'getting_started'         => :getting_started,  :as => 'getting_started'
    match 'privacy'                 => :privacy_settings, :as => 'privacy_settings'
    get 'getting_started_completed' => :getting_started_completed
    get 'confirm_email/:token'      => :confirm_email,    :as => 'confirm_email'
  end

  # This is a hack to overide a route created by devise.
  # I couldn't find anything in devise to skip that route, see Bug #961
  match 'users/edit' => redirect('/user/edit')

  devise_for :users, :controllers => {:registrations => "registrations",
                                      :password      => "devise/passwords",
                                      :sessions      => "sessions"}

  #legacy routes to support old invite routes
  get 'users/invitation/accept' => 'invitations#edit'
  get 'invitations/email' => 'invitations#email', :as => 'invite_email'
  get 'users/invitations' => 'invitations#new', :as => 'new_user_invitation'
  post 'users/invitations' => 'invitations#create', :as => 'new_user_invitation'

  get 'login' => redirect('/users/sign_in')

  scope 'admins', :controller => :admins do
    match :user_search
    get   :admin_inviter
    get   :weekly_user_stats
    get   :correlations
    get   :stats, :as => 'pod_stats'
    get   "add_invites/:invite_code_id" => 'admins#add_invites', :as => 'add_invites'
  end

  resource :profile, :only => [:edit, :update]
  resources :profiles, :only => [:show]


  resources :contacts,           :except => [:update, :create] do
    get :sharing, :on => :collection
  end
  resources :aspect_memberships, :only  => [:destroy, :create]
  resources :share_visibilities,  :only => [:update]
  resources :blocks, :only => [:create, :destroy]

  get 'i/:id' => 'invitation_codes#show', :as => 'invite_code'

  get 'people/refresh_search' => "people#refresh_search"
  resources :people, :except => [:edit, :update] do
    resources :status_messages
    resources :photos
    get :contacts
    get "aspect_membership_button" => :aspect_membership_dropdown, :as => "aspect_membership_button"
    get :hovercard

    member do
      get :last_post
    end

    collection do
      post 'by_handle' => :retrieve_remote, :as => 'person_by_handle'
      get :tag_index
    end
  end
  get '/u/:username' => 'people#show', :as => 'user_profile'
  get '/u/:username/profile_photo' => 'users#user_photo'


  # Federation

  controller :publics do
    get 'webfinger'             => :webfinger
    get 'hcard/users/:guid'     => :hcard
    get '.well-known/host-meta' => :host_meta
    post 'receive/users/:guid'  => :receive
    post 'receive/public'       => :receive_public
    get 'hub'                   => :hub
  end



  # External

  resources :services, :only => [:index, :destroy]
  controller :services do
    scope "/auth", :as => "auth" do
      match ':provider/callback' => :create
      match :failure
    end
    scope 'services' do
      match 'inviter/:provider' => :inviter, :as => 'service_inviter'
      match 'finder/:provider'  => :finder,  :as => 'friend_finder'
    end
  end

  scope 'api/v0', :controller => :apis do
    get :me
  end

 # namespace :api do
  #  namespace :v0 do
   #   get "/users/:username" => 'users#show', :as => 'user'
    #  get "/tags/:name" => 'tags#show', :as => 'tag'
    #end
  #end

  get 'community_spotlight' => "contacts#spotlight", :as => 'community_spotlight'
  # Mobile site

  get 'mobile/toggle', :to => 'home#toggle_mobile', :as => 'toggle_mobile'

  #Protocol Url
  get 'protocol' => redirect("http://wiki.diasporafoundation.org/Federation_Protocol_Overview")

  # Startpage
  root :to => 'home#show'
  
  #dauth
  get 'dauth/authorize/authorization_token' => 'authorize#show'
  post 'dauth/authorize/update' => 'authorize#update'
  post 'dauth/authorize/access_token' => 'authorize#access_token'
 
  namespace :dauth do
    resources :thirdparty_apps do
      member do
        post :revokexx
      end
    end
  end

  # API
  resources :manifests do
    member do
      get :download
    end
  end

end
