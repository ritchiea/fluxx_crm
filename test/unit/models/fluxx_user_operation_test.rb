require 'test_helper'

class FluxxUserOperationTest < ActiveSupport::TestCase

  def setup
    @connection = stub(:opt => {})
    @config = { :basedn => "dc=fluxx,dc=io" }
    @user_operation = FluxxUserOperation.new(@connection, 1, @config, Logger.new('/dev/null'))
  end
  
  #####################
  # AUTHENTICATION
  #####################

  test 'simple_bind - supports ldap protocol version 3' do
    @config[:allow_anonymous_access] = true
    assert_nothing_raised(LDAP::ResultError::ProtocolError) do
      @user_operation.simple_bind(3, nil, nil)
    end
  end

  test "simple_bind -  raise ProtocolError with unsupported version" do
    assert_raise(LDAP::ResultError::ProtocolError) do
      @user_operation.simple_bind(1, nil, nil)
    end
  end  
  
  test 'simple_bind - if allow_anonymous_access wont call find_by_login' do
    @config[:allow_anonymous_access] = true
    User.expects(:find_by_login).never
    @user_operation.simple_bind(3, 'username', 'password')
  end
  
  test 'simple_bind authenticates user' do
    pw = 'secret'
    user = User.make(:password => pw, :password_confirmation => pw )
    @user_operation.simple_bind(3, user.login, pw)
  end
  
  test 'unknown user raises InvalidCredentials' do
    assert_raise(LDAP::ResultError::InvalidCredentials) do
      @user_operation.simple_bind(3, 'missing_user', 'foo')
    end
  end
  
  test 'bad password raises InvalidCredentials' do
    pw = 'secret'
    user = User.make(:password => pw, :password_confirmation => pw )
    assert_raise(LDAP::ResultError::InvalidCredentials) do
      @user_operation.simple_bind(3, user.login, 'foo')
    end
  end

  ###############
  # FILTERS 
  ###############
  
  test 'parse_filter for osx address book format' do
    filter = [:or, [:substrings, "givenname", nil, "wal", nil], [:substrings, "sn", nil, "wal", nil], [:substrings, "mail", nil, "wal", nil], [:substrings, "cn", nil, "wal", nil]]
    query_str = @user_operation.parse_filter(filter)
    assert query_str, 'wal'
  end

  test 'parse_filter for outlook format' do
    filter = [:and, [:present, "mail"], [:or, [:substrings, "mail", nil, "wal", nil], [:substrings, "cn", nil, "wal", nil], [:substrings, "sn", nil, "wal", nil], [:substrings, "givenName", nil, "wal", nil]]]
    query_str = @user_operation.parse_filter(filter)
    assert query_str, 'wal'
  end
  
  
  ###############
  # SEARCH
  ###############
  
  test 'raises UnwillingToPerform if anonymous request and anonymous requests are disabled' do
    @config[:allow_anonymous_access] = false
    @user_operation.expects(:anonymous?).returns(true)
    assert_raise(LDAP::ResultError::UnwillingToPerform) do
      @user_operation.search(nil, nil, nil, nil)
    end
  end
  
  test 'raises UnwillingToPerform if bad dn' do
    @user_operation.expects(:anonymous?).returns(false)
    assert_raise(LDAP::ResultError::UnwillingToPerform) do
      @user_operation.search("dc=bad,dc=dn",nil, nil, nil)
    end
  end
  
  test 'calls user_search' do
    user = User.make(:first_name => "Bob", :last_name => "Tester")
    @user_operation.expects(:anonymous?).returns(false)
    User.expects(:search).returns([user])
    FluxxUserOperation.any_instance.stubs(:send_SearchResultEntry).returns(true)
    @user_operation.search(@config[:basedn], nil, nil,  [:eq, "cn", nil, "bob"])
  end

end