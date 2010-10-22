# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require File.join(File.dirname(__FILE__), 'blueprint')
require "rails/test_help"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Configure capybara for integration testing
require "capybara/rails"
Capybara.default_driver   = :rack_test
Capybara.default_selector = :css

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

def current_user
  @current_user unless @current_user == false
end

# Store the given user id in the session.
def current_user=(new_user)
  @current_user = new_user || false
end

def add_perms user
  user.has_role! 'listview_all'
  user.has_role! 'view_all'
  user.has_role! 'create_all'
  user.has_role! 'update_all'
  user.has_role! 'delete_all'
end

def login_as user
  add_perms user
  @controller.current_user = user
end

class ActionController::Base
  attr_accessor :current_user
end

# Do not audit log during tests
module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module Audited #:nodoc:
      module InstanceMethods
        private
        def write_audit(attrs)
          # Do nothing during tests
          # self.audits.create attrs if auditing_enabled
        end
      end
    end
  end
end

# Swap out the thinking sphinx sphinx interface with actual SQL
module ThinkingSphinx
  module SearchMethods
    module ClassMethods
      
      def search_for_ids(*args)
        paged_objects = search *args
        raw_ids = paged_objects.map &:id
        WillPaginate::Collection.create paged_objects.current_page, paged_objects.per_page, paged_objects.total_pages do |pager|
          pager.replace raw_ids
        end
      end
      
      def search(*args)
        self.paginate(:page => 1)
      end
    end
  end
end