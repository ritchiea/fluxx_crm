class AdminDefaults
  attr_accessor :workflows
  attr_accessor :alerts
  attr_accessor :roles
  attr_accessor :states
  attr_accessor :attributes 
  attr_accessor :methods
  attr_accessor :validations
  attr_accessor :pre_create 
  
  def initialize
  end
  @@single_defaults = nil
  def self.singleton
    @@single_defaults = AdminDefaults.new unless @@single_defaults
    @@single_defaults
  end
end