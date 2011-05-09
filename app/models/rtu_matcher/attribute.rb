module RTUMatcher
  class ComparingWrapper
    include Comparable

    def initialize(value)
      @value = value
    end

    def <=>(other)
      @value <=> other
    end

    def ==(other)
      @value == other
    end

    def due_in(other)
      @value <= other.from_now
    end

    def overdue_by(other)
      @value <= other.ago
    end
  end

  class Attribute < Base
    def initialize(opts)
      opts = HashWithIndifferentAccess.new(opts)
      @attribute = opts[:attribute]
      @value = opts[:value]
      @comparer = opts.fetch(:comparer, '==')
    end

    def matches?(rtu)
      attribute = wrap_attribute(rtu.model, @attribute)
      attribute.send(@comparer, @value)
    end

    def wrap_attribute(model, attribute)
      ComparingWrapper.new(model.send(attribute))
    end
  end
end
