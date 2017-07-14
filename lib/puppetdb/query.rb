require 'json'

module PuppetDB
  class Query
    attr_reader :sexpr

    def initialize(query = [])
      @sexpr = query
    end

    def self.[](*args)
      Query.new(args)
    end

    def self.maybe_promote(query)
      return Query.new(query) unless query.class == Query
      query
    end

    def empty?
      @sexpr.empty?
    end

    def compose(query)
      query = self.class.maybe_promote(query)

      # If an operand is the empty query ([]), compose returns a copy
      # of the non-empty operand. If both operands are empty, the
      # empty query is returned. If both operands are non-empty, the
      # compose continues.
      if query.empty? && !empty?
        Query.new(@sexpr)
      elsif empty? && !query.empty?
        Query.new(query.sexpr)
      elsif empty? && query.empty?
        Query.new([])
      else
        yield query
      end
    end

    def and(query)
      compose(query) { |q| Query.new([:and, @sexpr, q.sexpr]) }
    end

    def or(query)
      compose(query) { |q| Query.new([:or, @sexpr, q.sexpr]) }
    end

    def push(query)
      compose(query) { |q| Query.new(@sexpr.dup.push(q.sexpr)) }
    end

    def build
      JSON.dump(@sexpr)
    end
  end
end
