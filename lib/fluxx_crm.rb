require "formtastic" 
require "active_support" 
require "will_paginate" 
require "action_controller"
require "action_view"
require "fluxx_engine"

p "ESH: loading fluxx_crm"

# Some classes need to be required before or after; put those in these lists
CRM_EXTENSION_CLASSES_TO_PRELOAD = []
CRM_EXTENSION_CLASSES_TO_POSTLOAD = []

CRM_EXTENSION_CLASSES_TO_NOT_AUTOLOAD = CRM_EXTENSION_CLASSES_TO_PRELOAD + CRM_EXTENSION_CLASSES_TO_POSTLOAD
CRM_EXTENSION_CLASSES_TO_PRELOAD.each do |filename|
  require filename
end
Dir.glob("#{File.dirname(__FILE__).to_s}/extensions/**/*.rb").map{|filename| filename.gsub /\.rb$/, ''}.
  reject{|filename| CRM_EXTENSION_CLASSES_TO_NOT_AUTOLOAD.include?(filename) }.each {|filename| require filename }
CRM_EXTENSION_CLASSES_TO_POSTLOAD.each do |filename|
  require filename
end

Dir.glob("#{File.dirname(__FILE__).to_s}/fluxx_crm/**/*.rb").each do |fluxx_crm|
  require fluxx_crm.gsub /\.rb$/, ''
end

ActiveSupport::Dependencies.autoload_paths << File.dirname(__FILE__) + 
"/../app/helpers"
  Dir[File.dirname(__FILE__) + "/../app/helpers/**/*_helper.rb"].each do 
|file|
      ActionController::Base.helper "#{File.basename(file,'.rb').camelize}".constantize
  end

require 'rails/generators'

class InternalFluxxEnginePublicGenerator < Rails::Generators::Base
  include Rails::Generators::Actions

  def self.source_root
    File.join(File.dirname(__FILE__), 'templates')
  end

  def copy_fluxx_public_files
    public_dir = File.join(File.dirname(__FILE__), '../public')
    directory("#{public_dir}/images", 'public/images/fluxx_crm', :verbose => false)
    directory("#{public_dir}/javascripts", 'public/javascripts/fluxx_crm', :verbose => false)
    directory("#{public_dir}/stylesheets", 'public/stylesheets/fluxx_crm', :verbose => false)
  end
end

InternalFluxxEnginePublicGenerator.new.copy_fluxx_public_files
  