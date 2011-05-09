module RTUMatcher
  class And < Composed
    def &(matcher)
      add_matcher(matcher)
    end

    def matches?(rtu)
      @matchers.all?{|m| m.matches?(rtu)}
    end
  end
end
