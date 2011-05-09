module RTUMatcher
  class Base
    def self.from_json(json)
      from_hash(ActiveSupport::JSON.decode(json))
    end

    def self.from_hash(hash)
      if hash.key?('or')
        Or.new(*hash['or'].map{|m| from_hash(m)})
      elsif hash.key?('and')
        And.new(*hash['and'].map{|m| from_hash(m)})
      elsif hash.key?('class')
        hash['class'].constantize.new(hash['attributes'])
      end
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      attributes_hash = instance_variables.inject({}) do |hash, var|
        hash[var.gsub(/^@/, "").to_sym] = instance_variable_get(var) unless var == "@matchers"
        hash
      end

      {:class => self.class.name, :attributes => attributes_hash}
    end

    def &(matcher)
      And.new(self, matcher)
    end

    def |(matcher)
      Or.new(self, matcher)
    end

    def not
      Not.new(self)
    end
  end
end
