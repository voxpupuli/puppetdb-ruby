module PuppetDB
  class APIError < RuntimeError
    attr_reader :code, :response
    def initialize(response)
      @response = response
    end
  end

  class AccessDeniedError < APIError
  end

  class ForbiddenError < AccessDeniedError
  end

  class UnauthorizedError < AccessDeniedError
  end
end
