require 'fluxx_engine'

namespace :fluxx_crm do
  desc "Generates emails for all pending alerts"
  task :enqueue_alert_notifications => :environment do
    Alert.with_triggered_alerts! { |alert, models|
      alert.enqueue_for models
    }
  end

  desc "Sends all enqueued emails with alerts"
  task :deliver_enqueued_alert_emails => :enqueue_alert_notifications do
    ActionController::Base.asset_host = ENV['asset_host']
    ActionController::Base.asset_path = ENV['asset_path']
    
    AlertEmail.deliver_all
  end

  desc "Reload all document templates from their respective files"
  task :reload_doc_templates => :environment do
    WikiDocumentTemplate.reload_all_doc_templates
    ModelDocumentTemplate.reload_all_doc_templates
  end
  
  desc "load up all countries and states from the directory specified by variable geo_dir"
  task :geo => :environment do
    if RUBY_VERSION < '1.9'
      require 'fastercsv' 
    else
      require 'csv'
    end
    geo_dir = ENV['geo_dir'] || "#{File.dirname(__FILE__).to_s}/../db/geo"
    p "Processing countries"
    # TODO ESH: FIX THIS; is not ruby 1.9 compatible
    GeoCountry.without_auditing do
      CSV.foreach("#{geo_dir}/countries.csv", :headers => true) do |row|
      
        name = row['Country']
        fips104 = row['FIPS104']
        iso2 = row['ISO2']
        iso3 = row['ISO3']
        ison = row['ISON']
        internet = row['Internet']
        capital = row['Capital']
        map_reference = row['MapReference']
        nationality_singular = row['NationalitySingular']
        nationality_plural = row['NationalityPlural']
        currency = row['Currency']
        currency_code = row['CurrencyCode']
        population = row['Population']
        title = row['Title']
        comment = row['Comment']

        country = GeoCountry.find_by_fips104 fips104
        if country
          country.update_attributes :name => name, :fips104 => fips104, :iso2 => iso2, :iso3 => iso3, :ison => ison, :internet => internet, 
             :capital => capital, :map_reference => map_reference, :nationality_singular => nationality_singular, :nationality_plural => nationality_plural, 
             :currency => currency, :currency_code => currency_code, :population => population, :title => title, :comment => comment
        else
          GeoCountry.create :name => name, :fips104 => fips104, :iso2 => iso2, :iso3 => iso3, :ison => ison, :internet => internet, 
             :capital => capital, :map_reference => map_reference, :nationality_singular => nationality_singular, :nationality_plural => nationality_plural, 
             :currency => currency, :currency_code => currency_code, :population => population, :title => title, :comment => comment
        end
      end
    end

    GeoState.without_auditing do
      p "Processing States"
      CSV.foreach("#{geo_dir}/states.csv", :headers => true) do |row|
        country_name = row['country']
        region_id = row['region_id']
        region_name = row['region_name']
        country = GeoCountry.find_by_iso2 country_name
        country = GeoCountry.find_by_fips104 country_name unless country
        if country
          geo_state = GeoState.where(:geo_country_id => country.id, :fips_10_4 => region_id).first
          if geo_state
            geo_state.update_attributes :name => region_name
          else
            GeoState.create :name => region_name, :geo_country_id => country.id, :fips_10_4 => region_id
          end
        else
          raise Exception.new "Could not find a country with an iso2 #{country_name}"
        end
      end
    end
  end
  
  desc "load up all cities from the directory specified by variable geo_dir"
  task :geo_cities => :environment do
    if RUBY_VERSION < '1.9'
      require 'fastercsv' 
    else
      require 'csv' 
    end
    geo_dir = ENV['geo_dir'] || "#{File.dirname(__FILE__).to_s}/../db/geo"

    p "Processing cities"
    # TODO ESH: FIX THIS; is not ruby 1.9 compatible
    GeoCity.without_auditing do
      CSV.foreach("#{geo_dir}/GeoLiteCity-Location.csv", :headers => true) do |row|
        loc_id = row['locId']
        country_name = row['country']
        region_id = row['region']
        city_name = row['city']
        postal_code = row['postalCode']
        latitude = row ['latitude']
        longitude = row ['longitude']
        metro_code = row['metroCode']
        area_code = row['areaCode']
        unless city_name.blank? || ['01', 'A1', 'A2'].include?(country_name)
          country = GeoCountry.find_by_iso2 country_name
          country = GeoCountry.find_by_fips104 country_name unless country
          if country
            geo_state = GeoState.where(:geo_country_id => country.id, :fips_10_4 => region_id).first

            geo_state_id = (geo_state ? geo_state.id : nil)
            city = GeoCity.where(:name => city_name, :geo_state_id => geo_state_id, :geo_country_id => country.id).first
            if city
              city.update_attributes :postalCode => postal_code, :latitude => latitude, :longitude => longitude, :metro_code => metro_code, :area_code => area_code,
                :geo_country_id => country.id, :geo_state_id => geo_state_id, :original_id => loc_id
            else
              GeoCity.create :name => city_name, :postalCode => postal_code, :latitude => latitude, :longitude => longitude, :metro_code => metro_code, :area_code => area_code,
                :geo_country_id => country.id, :geo_state_id => geo_state_id, :original_id => loc_id
            end
          else
            p "Could not find a country with an iso2 #{country_name} for row=#{row.inspect}"
          end
        end
      end
    end
  end
  
  task :migrate_paperclip_to_s3 => :environment do
    a = Dir.glob("#{Rails.root}/public/system/documents/*/original/*")
    a.each do |filepath|
      begin
        doc = if filepath =~ /system\/documents\/(.*)_(.*)\/original\/(.*)$/
          client_id = $1
          model_id = $2
          filename = $3
          Client.use client_id
          ModelDocument.find model_id
        else
          filepath =~ /system\/documents\/(.*)\/original\/(.*)$/
          model_id = $1
          filename = $2
          ModelDocument.find model_id
        end

        p "ESH: for filepath=#{filepath}, have model_id = #{model_id}"
        file = File.open filepath
        doc.document = file
        p "ESH: for filepath=#{filepath}, about to save"
        doc.save(:validate => false)
        p "ESH: for filepath=#{filepath}, saved!!"
      rescue Exception => e
        p "ESH: for filepath=#{filepath}, hit an exception #{e.inspect}, #{e.backtrace.inspect}"
      end
    end
  end

  desc "Geocode all Organizations without coordinates."
  task :geocode_orgs => :environment do
    Organization.geocode_all
  end

end

namespace :fluxx_ldap_server do
  desc "Start Fluxx LDAP server"
  task :start => :environment do
    ldap_logger = ActiveSupport::BufferedLogger.new("#{Rails.root}/log/fluxx_ldap_server.log")
    ldap_config = File.join(Rails.root, 'config', "fluxx_ldap_server.yml")
    FluxxLdapServer.new(:logger => ldap_logger, :config => ldap_config).start
  end
end
