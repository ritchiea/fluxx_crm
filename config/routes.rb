Rails.application.routes.draw do |map|
  resources :favorite
  resources :geo_country
  resources :group
  resources :model_document
  resources :organization
  resources :user_organization
  resources :geo_city
  resources :geo_state
  resources :group_member
  resources :note
  resources :user
end

