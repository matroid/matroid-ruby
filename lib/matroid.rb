require 'dotenv/load'
require 'matroid/connection'
require 'matroid/version'
require 'matroid/detector'
module Matroid
  @client_id = ENV['MATROID_CLIENT_ID']
  @client_secret = ENV['MATROID_CLIENT_SECRET']

  class << self

    # Authenticates access for Matroid API
    # @example
    #  Matroid.authenticate("<your_client_id>", "<your_client_secret>")
    # @param client_id [String]
    # @param client_secret [String]
    # @return [Boolean] If the the access token is successfully created.
    def authenticate(client_id = nil, client_secret = nil)
      return true unless @token.nil? || @token.expired?
      if client_id && client_secret
        raise BAD_CLIENT_VARIABLES_ERR if get_token(client_id, client_secret).nil?
        @client_id, @client_secret = client_id, client_secret
      elsif (@client_id.nil? || @client_secret.nil?) && !environment_variables?
        raise NO_ENV_VARIABLES_ERR
      else
        raise BAD_ENV_VARIABLES_ERR if get_token(@client_id, @client_secret).nil?
      end

      true
    end

    # Calls ::show on the current token (if it exists).
    def show_token
      if @token
        @token.show
      end
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

  end
end
