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
    has_many :alert_recipients, :dependent => :destroy
    has_many :alert_users, :class_name => AlertRecipient.name, :conditions => ["alert_recipients.user_id IS NOT NULL"]
    has_many :recipients, :through => :alert_users, :source => 'user'

    serialize :filter, Hash
    validates :name, :presence => true, :uniqueness => true

    class_inheritable_hash :recipient_roles
    self.recipient_roles = HashWithIndifferentAccess.new

    after_initialize :on_init
    after_save :save_roles
    before_validation(:on => :create) do
      self.last_realtime_update_id = RealtimeUpdate.maximum(:id) if self.last_realtime_update_id.nil?
    end

    insta_search
  end

  class_methods do
    def recipients
      User.joins(:user_profile).where("user_profiles.name = 'Employee' OR user_profiles.name = 'Board'").order("users.first_name, users.last_name ASC")
    end

    def with_triggered_alerts!(skip_filter = false, &alert_processing_block)
      Alert.find_each do |alert|
        matching_models = []

        last_realtime_update_id = alert.last_realtime_update_id || -1
        RealtimeUpdate.where("id > ?", last_realtime_update_id).order('id asc').find_each do |rtu|
          last_realtime_update_id = rtu.id
          matching_models << rtu.model if skip_filter || alert.should_be_triggered_by_model?(rtu.model)
        end

        matching_models = matching_models.compact.uniq

        alert.update_attribute(:last_realtime_update_id, last_realtime_update_id)
        alert_processing_block.call(alert, matching_models) unless matching_models.empty?
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

    def attr_recipient_role(name, opts)
      recipient_finder, friendly_name = opts.values_at(:recipient_finder, :friendly_name)

      friendly_name ||= name.to_s.humanize

      self.recipient_roles[name] = {:friendly_name => friendly_name, :recipient_finder => recipient_finder}

      attr_reader name

      define_method("#{name}=") do |value|
        bool_value = if value == "1"
                  true
                elsif value == "0"
                  false
                else
                  !!value
                end

        instance_variable_set("@#{name}", bool_value)
      end
    end
  end

  instance_methods do
    def target_class
      self.class.name.gsub(/^(.+)Alert$/, '\1').constantize
    end

    def should_be_triggered_by_model?(model)
      return false unless model.is_a?(target_class)

      filter.map do |matcher_name, matcher_hash|
        attribute_value = call_method_chain(model, matcher_hash[:attribute])
        comparable_attribute_value = ComparingWrapper.new(attribute_value)
        matcher_hash[:values].map do |value|
          comparable_attribute_value.send(matcher_hash[:comparer], value)
        end.any?
      end.all?
    end

    def call_method_chain(object, method_chain)
      method_chain.to_s.split('.').inject(object){|object, method_name| object.send(method_name)}
    end

    def model_recipients(model)
      alert_recipients.map do |alert_recipient|
        if alert_recipient.user
          alert_recipient.user
        else
          role_recipient_opts = self.class.recipient_roles[alert_recipient.rtu_model_user_method.to_sym]
          role_recipient_opts[:recipient_finder].call(model) if role_recipient_opts
        end
      end.compact.uniq
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

    def on_init
      create_default_filter
      load_roles
    end

    def create_default_filter
      self.filter ||= {}
    end

    def load_roles
      self.class.recipient_roles.keys.each do |recipient_role|
        is_set = self.alert_recipients.where(:rtu_model_user_method => recipient_role).exists?
        send("#{recipient_role}=", is_set)
      end
    end

    def save_roles
      self.class.recipient_roles.keys.each do |recipient_role|
        save_role(recipient_role)
      end
    end

    def save_role(role_name)
      is_a_recipient = send(role_name)
      was_a_recipient = self.alert_recipients.where(:rtu_model_user_method => role_name).exists?

      return if was_a_recipient && is_a_recipient
      return if !was_a_recipient && !is_a_recipient

      if is_a_recipient
        AlertRecipient.where(:alert_id => self.id, :rtu_model_user_method => role_name).create!
      else
        AlertRecipient.where(:alert_id => self.id, :rtu_model_user_method => role_name).each(&:destroy)
      end
    end
  end
end
