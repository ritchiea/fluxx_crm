require 'ldap/server'
require 'ldap/server/util'

class FluxxUserOperation < LDAP::Server::Operation

  def initialize(connection, message_id, config, logger)
    @config, @logger = config, logger
    super(connection, message_id)
   end

  def search(basedn, scope, deref, filter)
    # @logger.debug "Search: basedn=#{basedn.inspect}, scope=#{scope.inspect}, deref=#{deref.inspect}, filter=#{filter.inspect}"
    if anonymous?
      @logger.info  "Received anonymous search request."
      unless @config[:allow_anonymous_access]
        @logger.info  "allow_anonymous_access is false, raising UnwillingToPerform exception"
        raise LDAP::ResultError::UnwillingToPerform
      end
    else
      @logger.info  "Received search request."
    end
    
    unless basedn.ends_with?(@config[:basedn])
      @logger.info "Denying request with bad basedn (wanted \"#{@config[:basedn]}\", but got \"#{basedn}\")"
      raise LDAP::ResultError::UnwillingToPerform, "Bad base DN"
    end

    # parse filter to pull out query string
    @logger.debug "Filter: #{filter.inspect}"
    query_string = parse_filter(filter)
    @records = user_search(basedn, query_string)
    
    @records.each do |record|      
      begin
        ret = record.to_ldap_entry
      rescue
        @logger.error "ERROR converting User instance to ldap entry: #{$!}"
        raise LDAP::ResultError::OperationsError, "Error encountered during processing."
      end
      ret_basedn = "uid=#{ret["uid"]},#{basedn}"
      @logger.debug "Sending #{ret_basedn} - #{ret.inspect}"
      send_SearchResultEntry(ret_basedn, ret)
    end
  end
  
  def user_search(basedn, query_string)
    begin
      @logger.info "Running User.search(\"#{query_string}\")"
      records = User.search(query_string)
      records.compact! # fluxx search results can have nils in array
      @logger.info "Found #{records.size} records."
      return records
    rescue Exception => e
      @logger.error "ERROR performing User.search: #{$!}"
      raise LDAP::ResultError::OperationsError, "Unable to perform search"
    end
  end
  
  # parses/handles the following filter formats
  # mozilla and OSX address book: [:or, [:substrings, "givenname", nil, "wal", nil], [:substrings, "sn", nil, "wal", nil], [:substrings, "mail", nil, "wal", nil], [:substrings, "cn", nil, "wal", nil]]
  # Outlook: [:and, [:present, "mail"], [:or, [:substrings, "mail", nil, "wal", nil], [:substrings, "cn", nil, "wal", nil], [:substrings, "sn", nil, "wal", nil], [:substrings, "givenName", nil, "wal", nil]]]
  # ldapper:  [:substrings, "cn", nil, nil, "wal", nil], [:and, [:eq, "objectclass", nil, "person"], [:substrings, "mail", nil, nil, "wal", nil]]
  # command line: ldapsearch -x -H ldap://127.0.0.1:1389/ -b "dc=domain,dc=com" "(cn=wal)" : [:eq, "cn", nil, "wal"]
  # invalid (we dont allow search on address): [:eq, "address", nil, "wal"]
  def parse_filter(filter)
    return nil unless filter && filter.is_a?(Array)
    # handle reg array
    query_string = parse_query(filter)
    return query_string if query_string

    # handle multi-dimensional array
    filter.each do |q|
      query_string = parse_query(q)
      return query_string if query_string
    end
    raise LDAP::ResultError::UnwillingToPerform "Unable to parse query:  #{filter.inspect}"
  end
  
  # parse ldap query filter - recursive to handle multi dimensional arrays
  def parse_query(q)
    return nil unless q && q.is_a?(Array)
    return nil unless q.length > 2
    if [:eq, :approx, :substrings].include? q[0]
      return nil unless (%w{mail cn givenname sn}.include? q[1].downcase)
      return q[2..-1].compact.first # take the first non-nil element as the search string
    else
      return parse_query(q[1]) # recurse
    end
    nil
  end

  # Authenticate request
  def simple_bind(version, dn, password)
    @logger.info "fluxx_crm simple_bind:  version=#{version}, dn=#{dn}"
    if version != 3
      raise LDAP::ResultError::ProtocolError, "version 3 only"
    end
    return true if @config[:allow_anonymous_access]

    user = User.find_by_login(dn)
    unless user && user.valid_credentials?(password)
      @logger.info "raising LDAP::ResultError::InvalidCredentials"
      raise LDAP::ResultError::InvalidCredentials 
    end
  end
  
end
