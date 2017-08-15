require 'base64'
require 'json'
require 'httpclient/webagent-cookie' # stops warning found here: https://github.com/nahi/httpclient/issues/252
require 'httpclient'
require 'date'

BASE_API_URI       = 'https://www.matroid.com/api/v1/'
DEFAULT_GRANT_TYPE = 'client_credentials'
TOKEN_RESOURCE     = 'oauth/token'
VERBS              = %w(get post)

module Matroid

  # @attr_reader [Token] The current stored token object
  class << self
    attr_reader :token, :base_api_uri, :client

    # Changes the default base api uri. This is used primarily for testing purposes.
    # @param uri [String]
    def set_base_uri(uri)
      @base_api_uri = uri
    end

    VERBS.each do |verb|
      define_method verb do |endpoint, *params|
        send_request(verb, endpoint, *params)
      end
    end

    def parse_response(response)
      if valid_json?(response.body)
        status = response.status_code
        parsed_response = JSON.parse(response.body)
        if status != 200
          err_msg = JSON.pretty_generate(parsed_response)
          raise Error::RateLimitError.new(err_msg) if status == 429
          raise Error::InvalidQueryError.new(err_msg) if status == 422
          raise Error::PaymentError.new(err_msg) if status == 402
          raise Error::ServerError.new(err_msg) if status / 100 == 5
          raise Error::APIError.new(err_msg)
        end

        parsed_response
      else
        p response
        raise Error::APIError.new(response.body)
      end
    end

    private

    def get_token(client_id, client_secret)
      @base_api_uri = BASE_API_URI if @base_api_uri.nil?
      url = @base_api_uri + TOKEN_RESOURCE
      params = auth_params(client_id, client_secret)
      @client = HTTPClient.new
      response = @client.post(url, body: params)
      return false unless response.status_code == 200
      @token = Token.new(JSON.parse(response.body))
      @client.base_url = @base_api_uri
      @client.default_header = { 'Authorization' => @token.authorization_header }
    end

    def send_request(verb, path, params = {})
      path = URI.escape(path)

      # refreshes token with each call
      authenticate

      case verb
      when 'get'
        response = @client.get(path, body: params)
      when 'post'
        response = @client.post(path, body: params)
      end

      parse_response(response)
    end

    def valid_json?(json)
      begin
        JSON.parse(json)
        return true
      rescue JSON::ParserError => e
        return false
      end
    end

    def auth_params(client_id, client_secret)
      {
        'client_id' => client_id,
        'client_secret' => client_secret,
        'grant_type' => DEFAULT_GRANT_TYPE
      }
    end

    def environment_variables?
      !ENV['MATROID_CLIENT_ID'].nil? && !ENV['MATROID_CLIENT_SECRET'].nil?
    end

  end

  # Represents an OAuth access token
  # @attr [String]   token_type     ex: "Bearer"
  # @attr [String]   token_str      The actual access token
  # @attr [DateTime] born           When the token was created
  # @attr [String]   lifetime       Seconds until token expired
  class Token
    attr_reader :born, :lifetime, :acces_token
    def initialize(options = {})
      @token_type = options['token_type']
      @access_token = options['access_token']
      @born = DateTime.now
      @lifetime = options['expires_in']
    end

    def authorization_header
      "#{@token_type} #{@access_token}"
    end

    # Checks if the current token is expired
    # @return [Boolean]
    def expired?
      lifetime_in_days = time_in_seconds(@lifetime)
      @born + lifetime_in_days < DateTime.now
    end


    # @return [Numeric] Time left before token expires (in seconds).
    def time_remaining
      lifetime_in_days = time_in_seconds(@lifetime)
      remaining = lifetime_in_days - (DateTime.now - @born)
      remaining > 0 ? time_in_seconds(remaining) : 0
    end

    def time_in_seconds(t)
      t * 24.0 * 60 * 60
    end

    def to_s
      JSON.pretty_generate({
        access_token: @access_token,
        born: @born,
        lifetime: @lifetime
      })
    end
  end
end
