require "formtastic" 
require "active_support" 
require "will_paginate" 
require "action_controller"
require "action_view"

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
