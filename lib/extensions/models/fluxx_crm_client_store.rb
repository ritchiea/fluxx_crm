module FluxxCrmClientStore
  extend FluxxModuleHelper
  
  when_included do
    include ::FluxxClientStore
    # When a dashboard client_store is updated, inspect the contents to see if any alerts have been added/updated/deleted
    belongs_to :user
    after_create :update_alerts
    after_save :update_alerts
  end
  
  class_methods do
    def dashboard_card_gets_email? card
      card["settings"] && card["settings"]["emailNotifications"] && card["settings"]["emailNotifications"].is_a?(TrueClass)
    end
  end
  
  instance_methods do
    def update_alerts
      alerted_cards = dashboard_cards.map do |card|
        # 
        if ClientStore.dashboard_card_gets_email? card
          # Find the URL, and the controller for that URL, then grab the params for the controller
          url = card['listing']['url'] if card['listing']
          controller_klass = if url
            url_mapping = ActionController::Routing::Routes.recognize_path url
            if url_mapping
              controller = url_mapping[:controller]
              if controller
                Kernel.const_get "#{controller.titlecase.gsub(' ', '')}Controller" rescue nil
              end
            end
          end
          
          card_id = card['uid']
          card_title = card['title']
          
          {:model_controller_type => controller_klass, :dashboard_card_id => card_id, :filter => ClientStore.dashboard_card_params(card), :title => card_title}
        end
      end.compact
      p "ESH: calling resolve_for_dashboard"
      Alert.resolve_for_dashboard self, alerted_cards
    end
  end
end