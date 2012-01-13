require 'ldap/server'
require 'logger'

class FluxxLdapServer

  # Create a new server.  Available options:
  # :config - location of ldap server yaml file.  Defaults to Rails.root/config/fluxx_ldap_server.yml
  # :logger - Logger.  defaults to STDOUT
  # see:  https://github.com/candlerb/ruby-ldapserver/blob/master/lib/ldap/server/server.rb
  def initialize(options={})
    config = options.has_key?(:config) ? options[:config] : File.join(Rails.root, 'config', "fluxx_ldap_server.yml")
    puts "loading config from: #{config}"
    @config = YAML.load_file(config)[Rails.env].symbolize_keys
    @logger = options.has_key?(:logger) ? options[:logger] : Logger.new(STDOUT)
  end
  
  def start
    operation_class = @config[:operation_class]
    puts "starting FluxxLdapServer with operation_class #{operation_class}"
    s = LDAP::Server.new(
      :port => @config[:port],
      :nodelay => true,
      :listen => 10,
      :operation_class => operation_class.constantize,
      :operation_args => [@config, @logger]
    )
    s.run_tcpserver
    s.join
  end

end
