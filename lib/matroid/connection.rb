require 'base64'
require 'json'
require 'restclient'
require 'date'

BASE_API_URI       = 'https://www.matroid.com/api/0.1'
DEFAULT_GRANT_TYPE = 'client_credentials'
TOKEN_RESOURCE     = '/oauth/token'
VERBS              = %w(get post)

# error messages
NO_ENV_VARIABLES_ERR     = 'AuthenticationError: "MATROID_CLIENT_ID" and "MATROID_CLIENT_SECRET" not found in environment'
BAD_ENV_VARIABLES_ERR    = 'AuthenticationError: problem using environment variables "MATROID_CLIENT_ID" and "MATROID_CLIENT_SECRET"'
BAD_CLIENT_VARIABLES_ERR = 'AuthenticationError: problem using client variables provided'

module Matroid

  # @attr_reader [Token] The current stored token object
  class << self
    attr_reader :token

    # Authenticates access for Matroid API
    # @example
    #  Matroid.authenticate("<your_client_id>", "<your_client_secret>")
    # @param client_id [String]
    # @param client_secret [String]
    # @return [Boolean] If the the access token is successfully created.
    def authenticate(client_id = nil, client_secret = nil)
      return true unless @token.nil? or @token.expired?
      if client_id and client_secret
        raise BAD_CLIENT_VARIABLES_ERR if get_token(client_id, client_secret).nil?
        @client_id, @client_secret = client_id, client_secret
      elsif (@client_id.nil? or @client_secret.nil?) and !environment_variables?
        raise NO_ENV_VARIABLES_ERR
      else
        client_id, client_secret = ENV['MATROID_CLIENT_ID'], ENV['MATROID_CLIENT_SECRET']
        raise BAD_ENV_VARIABLES_ERR if get_token(client_id, client_secret).nil?
        @client_id, @client_secret = client_id, client_secret
      end

      true
    end

    # Retrieves the authenticated user's account information
    # @return The account info as a parsed JSON
    # @example
    #   {
    #     "account" => {
    #       "credits" => {
    #         "concurrentTrainLimit" =>1,
    #         "held" => 3496,
    #         "plan" => "premium",
    #         "daily" => {
    #           "used" => 36842,
    #           "available" => 100000
    #         },
    #         "monthly" => {
    #           "used" => 36842,
    #           "available" => 1000000
    #         }
    #       }
    #     }
    #   }
    def account_info
      get('/account')
    end

    VERBS.each do |verb|
      define_method verb do |endpoint, *params|
        send_request(verb, endpoint, *params)
      end
    end

    # Calls ::show on the current token (if it exists).
    def show_token
      if @token
        @token.show
      end
    end

    # Retrieves video classification data. Requires a video_id from
    # {Detector#classify_video_file} or {Detector#classify_video_url}
    # format 'json'/'csv'
    # @note A "video_id" is needed to get the classification results
    # @example
    #   <Detector >.get_video_results(video_id: "23498503uf0dd09", threshold: 30, format: 'json')
    # @param video_id [String]
    # @param threshold [Numeric, nil]
    # @param
    def get_video_results(video_id, *args)
      get("/videos/#{video_id}", *args)
    end

    private

    def get_token(client_id, client_secret)
      url = BASE_API_URI + TOKEN_RESOURCE
      params = auth_params(client_id, client_secret)
      begin
        response = RestClient.post(url, params)
      rescue RestClient::ExceptionWithResponse => e
        puts JSON.pretty_generate(JSON.parse(e.response))
        @token = nil
        return false
      end

      @token = Token.new(JSON.parse(response))
    end

    def send_request(verb, path, *params)
      url = path.start_with?('http') ? path : BASE_API_URI + path
      url, query = *url.split('?')
      url = URI::encode(url)
      url << "?#{query}" if query

      # refreshes token with each call
      authenticate

      begin
        case verb
        when 'get'
          params << { 'Authorization' => @token.authorization_header }
          response = RestClient.get(url, *params)
        when 'post'
          params << {} if params.empty?
          params << { 'Authorization' => @token.authorization_header }
          response = RestClient.post(url, *params)
        end
      rescue RestClient::ExceptionWithResponse => e
        raise JSON.pretty_generate(JSON.parse(e.response))
      end

      JSON.parse(response)
    end

    def auth_params(client_id, client_secret)
      {
        'client_id' => client_id,
        'client_secret' => client_secret,
        'grant_type' => DEFAULT_GRANT_TYPE
      }
    end

    def environment_variables?
      ENV['MATROID_CLIENT_ID'] and ENV['MATROID_CLIENT_SECRET']
    end

  end

  # Represents an OAuth access token
  # @attr [String]   token_type     ex: "Bearer"
  # @attr [String]   token_str      The actual access token
  # @attr [DateTime] born           When the token was created
  # @attr [String]   lifetime       Seconds until token expired
  class Token
    attr_reader :born, :lifetime
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
      lifetime_in_days = @lifetime / 24.0 / 60 / 60
      @born + lifetime_in_days < DateTime.now
    end


    # @return [Numeric] Time left before token expires (in seconds).
    def time_remaining
      lifetime_in_days = @lifetime / 24.0 / 60 / 60
      remaining = lifetime_in_days - (DateTime.now - @born)
      remaining > 0 ? remaining * 24.0 * 60 * 60  : 0
    end

    def show
      {
        access_token: @access_token,
        born: @born,
        lifetime: @lifetime
      }
    end
  end
end
