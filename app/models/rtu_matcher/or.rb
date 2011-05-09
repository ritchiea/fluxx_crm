module RTUMatcher
  class Or < Composed
    def |(matcher)
      add_matcher(matcher)
    end

    def matches?(rtu)
      @matchers.any?{|m| m.matches?(rtu)}
    end
  end
end
