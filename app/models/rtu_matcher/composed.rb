module RTUMatcher
  class Composed < Base
    def initialize(*matchers)
      @matchers = matchers
    end

    def to_hash
      { self.class.name.split("::").last.underscore.to_sym => @matchers.map { |matcher| matcher.to_hash } }
    end

  private

    def add_matcher(matcher)
      @matchers << matcher
      self
    end
  end
end
