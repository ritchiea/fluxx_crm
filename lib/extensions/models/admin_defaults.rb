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
    self.workflows = [['New Request Workflow', Request.name], ['New Report Workflow', RequestReport.name], ['New Transaction Workflow', RequestTransaction.name]],
    self.alerts = [['New Report Alert', RequestReportsController.name]],
    self.roles = [['New Program Role', Program.name]],
    self.states = [['New Request State', Request.name], ['New Report State', RequestReport.name], ['New Transaction State', RequestTransaction.name]],
    self.attributes = [['New Request Attribute', Request.name], ['New Report Attribute', RequestReport.name], ['New Transaction Attribute', RequestTransaction.name], ['New LOI Attribute', Loi.name]],
    self.methods = [['New Request Model Method', Request.name], ['New Report Model Method', RequestReport.name], ['New Transaction Model Method', RequestTransaction.name]],
    self.validations = [['New Request Model Validation', Request.name], ['New Report Model Validation', RequestReport.name], ['New Transaction Model Validation', RequestTransaction.name]],
    self.pre_create = ['GrantRequest']
  end
  @@single_defaults = nil
  def self.singleton
    @@single_defaults = AdminDefaults.new unless @@single_defaults
    @@single_defaults
  end
end