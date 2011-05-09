module RTUMatcher
  class Not < Base
    def initialize(matcher)
      @matcher = matcher
    end

    def matches?(rtu)
      !@matcher.matches?(rtu)
    end
  end
end
