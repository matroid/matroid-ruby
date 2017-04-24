module Matroid
  module Error
    class APIError < StandardError; end
    class APIConnectionError < APIError; end
    class AuthorizationError < APIError; end
    class InvalidQueryError < APIError; end
    class ServerError < APIError; end
    class RateLimitError < APIError; end
    class PaymentError < APIError; end
    class MediaError < APIError; end
  end
end
