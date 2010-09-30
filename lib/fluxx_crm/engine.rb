require "rails"
require "action_controller"

module FluxxCrm
  class Engine < Rails::Engine
    initializer 'fluxx_crm.add_compass_hooks', :after=> :disable_dependency_loading do |app|
      Sass::Plugin.add_template_location "#{File.dirname(__FILE__).to_s}/../../app/stylesheets", "public/stylesheets/compiled/fluxx_crm"
    end
    rake_tasks do
      load File.expand_path('../../tasks.rb', __FILE__)
    end
  end
end
