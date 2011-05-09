module FluxxCrmAlert
  class ComparingWrapper
    include Comparable

    def initialize(value)
      @value = value
    end

    def <=>(other)
      @value <=> Float(other)
    rescue ArgumentError
      @value <=> other
    end

    def ==(other)
      @value == other
    end

    def due_in(other)
      @value <= other.to_i.days.from_now
    end

    def overdue_by(other)
      @value <= other.to_i.days.ago
    end

    def in(other)
      @value.include?(other)
    end
  end

  extend FluxxModuleHelper

  when_included do
    has_many :alert_recipients
    has_many :alert_users, :class_name => AlertRecipient.name, :conditions => ["alert_recipients.user_id IS NOT NULL"]
    has_many :recipients, :through => :alert_users, :source => 'user'
    validates :name, :presence => true, :uniqueness => true
    serialize :filter, Hash
    after_initialize :create_default_filter
    before_validation(:on => :create) do
      self.last_realtime_update_id = RealtimeUpdate.maximum(:id) if self.last_realtime_update_id.nil?
    end
    insta_search
  end

  class_methods do
    def with_triggered_alerts!(&alert_processing_block)
      Alert.find_each do |alert|
        matching_rtus = []
        last_realtime_update_id = alert.last_realtime_update_id || -1
        RealtimeUpdate.where("id > ?", last_realtime_update_id).order('id asc').find_each do |rtu|
          last_realtime_update_id = rtu.id
          matching_rtus << rtu if alert.should_be_triggered?(rtu)
        end

        alert.update_attribute(:last_realtime_update_id, last_realtime_update_id)
        alert_processing_block.call(alert, matching_rtus) unless matching_rtus.empty?
      end
    end

    def alertable_classes
      ActiveRecord::Base.subclasses.select{|ar_class| ar_class.constants.include?("SEARCH_ATTRIBUTES")}
    end

    def alertable_classes_attributes
      Alert.alertable_classes.inject({}) do |hash, klass|
        hash[klass.name] = klass.const_get("SEARCH_ATTRIBUTES")
        hash
      end
    end

    def attr_matcher(*matchers)
      matchers.each { |opts|
        if opts.is_a?(Hash)
          name, comparer, attribute = opts.values_at(:name, :comparer, :attribute)
        else
          name, comparer, attribute = opts.to_s, nil, nil
        end

        attribute ||= name
        comparer ||= '=='

        define_method(name) do
          return nil unless filter[name]
          filter[name][:values]
        end

        define_method("#{name}=") do |value|
          if value.blank?
            filter.delete(name)
          else
            filter[name] = {:values => [value].flatten, :comparer => comparer, :attribute => attribute }
          end
        end
      }
    end
  end

  instance_methods do
    def target_class
      self.class.name.gsub(/^(.+)Alert$/, '\1').constantize
    end

    def should_be_triggered?(rtu)
      return false unless rtu.model.is_a?(target_class)

      filter.map do |matcher_name, matcher_hash|
        attribute_value = call_method_chain(rtu.model, matcher_hash[:attribute])
        comparable_attribute_value = ComparingWrapper.new(attribute_value)
        matcher_hash[:values].map do |value|
          comparable_attribute_value.send(matcher_hash[:comparer], value)
        end.any?
      end.all?
    end

    def call_method_chain(object, method_chain)
      method_chain.to_s.split('.').inject(object){|object, method_name| object.send(method_name)}
    end

    def rtu_recipients(rtu)
      alert_recipients.map do |alert_recipient|
        if alert_recipient.user
          alert_recipient.user
        else
          user_id = rtu.model.send(alert_recipient.rtu_model_user_method)
          User.find(user_id)
        end
      end.uniq
    end

    def to_liquid
      {}
    end

    def liquid_subject(locals={})
      Liquid::Template.parse(subject).render(locals.stringify_keys.merge('alert' => self))
    end

    def liquid_body(locals={})
      Liquid::Template.parse(body).render(locals.stringify_keys.merge('alert' => self))
    end

    def create_default_filter
      self.filter ||= {}
    end
  end
end
