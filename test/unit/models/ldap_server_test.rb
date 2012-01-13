require 'test_helper'

CONFIG_FILE = <<EOF
development: &defaults
  basedn: dc=fluxx,dc=io
  port: 1389
  operation_class: FluxxUserOperation
  allow_anonymous_access: false
fastdev:
  <<: *defaults
test:
  <<: *defaults
EOF

class LdapServerTest < ActiveSupport::TestCase
  
  test "reads config file on new" do
    YAML.expects(:load_file).with(File.join(Rails.root, 'config', "fluxx_ldap_server.yml")).returns(YAML.load(CONFIG_FILE))
    s = FluxxLdapServer.new
  end
  
  test "read a custom config file if passed to new" do
    YAML.expects(:load_file).with("/foo/custom.yml").returns(YAML.load(CONFIG_FILE))
    s = FluxxLdapServer.new({:config => "/foo/custom.yml"})
  end

  test "defaults to logging to STDOUT" do
    Logger.expects(:new).with(STDOUT).returns(true)
    s = FluxxLdapServer.new
  end

  test 'starting ldap server' do
      fls = FluxxLdapServer.new
      lds = mock
      LDAP::Server.expects(:new).returns(lds)
      lds.expects(:run_tcpserver)
      lds.expects(:join)
      fls.start
  end

end