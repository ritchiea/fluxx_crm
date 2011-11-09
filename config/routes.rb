Rails.application.routes.draw do
  resources :multi_element_values

  resources :multi_element_groups

  resources :admin_items

  resources :admin_cards
  resources :user_permissions

  resources :roles

  resources :modules

  resources :work_tasks

  resources :bank_accounts

  resources :favorites
  resources :geo_countries
  resources :groups
  resources :model_documents
  resources :model_document_types
  resources :documents
  resources :organizations
  resources :user_organizations
  resources :geo_cities
  resources :geo_states
  resources :group_members
  resources :notes
  resources :role_users
  resources :users
  resources :projects
  resources :project_lists
  resources :project_list_items
  resources :project_users
  resources :project_organizations
  resources :wiki_documents
  resources :wiki_document_templates
  resources :model_document_templates
  resources :alerts
  
  match 'users_impersonate', :to => 'users#impersonate', :as => "users_impersonate"
  match 'user_sessions_impersonate', :to => 'user_sessions#impersonate', :as => "user_sessions_impersonate"
  
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  match 'portal', :controller => :user_sessions
  
  match 'forgot_password' => 'user_sessions#forgot_password', :as => :forgot_password, :via => :get
  match 'forgot_password' => 'user_sessions#forgot_password_lookup_email', :as => :forgot_password, :via => :post

  put 'reset_password/:reset_password_code' => 'users#reset_password_submit', :as => :reset_password, :via => :put
  get 'reset_password/:reset_password_code' => 'users#reset_password', :as => :reset_password, :via => :get  
  
end

