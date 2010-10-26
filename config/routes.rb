Rails.application.routes.draw do
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
end

