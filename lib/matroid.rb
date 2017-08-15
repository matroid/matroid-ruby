require 'dotenv/load'
require 'matroid/connection'
require 'matroid/version'
require 'matroid/detector'
require 'matroid/error'

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
        err_msg = 'problem using environment variables "MATROID_CLIENT_ID" and "MATROID_CLIENT_SECRET"'
        new_token = get_token(client_id, client_secret)
        raise Error::AuthorizationError.new(err_msg) if new_token.nil?
        @client_id, @client_secret = client_id, client_secret
      elsif (@client_id.nil? || @client_secret.nil?) && !environment_variables?
        err_msg = '"MATROID_CLIENT_ID" and "MATROID_CLIENT_SECRET" not found in environment'
        raise Error::AuthorizationError.new(err_msg)
      else
        err_msg = 'Problem using client variables provided'
        raise Error::AuthorizationError.new(err_msg) if get_token(@client_id, @client_secret).nil?
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
      get('account')
    end

    # Retrieves video classification data. Requires a video_id from
    # {Detector#classify_video_file} or {Detector#classify_video_url}
    # format 'json'/'csv'
    # @note A "video_id" is needed to get the classification results
    # @example
    #   <Detector >.get_video_results(video_id: "23498503uf0dd09", threshold: 0.30, format: 'json')
    # @param video_id [String]
    # @param threshold [Numeric, nil]
    # @param
    # Sample format
    # {
    #   "download_progress": 100,
    #   "classification_progress": 8,
    #   "status": "Video Download Complete. Classifying Video",
    #   "label_dict": {"0":"cat","1":"dog"},
    #   "state": "running",
    #   "detections": {
    #        "1.5": [{ "labels": { "0": 0.10 } }],
    #        "2": [{ "labels": { "0": 0.98, "1": 0.10 } }],
    #        "5": [{ "labels": { "0": 0.75 } }]
    #    }
    # }
    #
    # {
    #   "download_progress": 100,
    #   "classification_progress": 8,
    #   "status": "Video Download Complete. Classifying Video",
    #   "label_dict": {"0":"man","1":"woman"},
    #   "state": "running",
    #   "detections": {
    #     "89": [
    #       {
    #         "labels": {
    #           "0": 0.95
    #         },
    #         "bbox": {
    #          "left": 0.2377,
    #          "top": 0.2021,
    #          "width": 0.1628,
    #          "height": 0.3896,
    #        }
    #       }
    #     ],
    #     "92": [
    #       {
    #         "labels": {
    #           "0": 0.16,
    #           "2": 0.80
    #         },
    #         "bbox": {
    #           "left": 0.7576,
    #           "top": 0.2375,
    #           "width": 0.0597,
    #           "height": 0.1313,
    #         }
    #       },
    #       {
    #         "labels": {
    #           "0": 0.89,
    #         },
    #         "bbox": {
    #           "left": 0.5047,
    #           "top": 0.1708,
    #           "width": 0.055,
    #           "height": 0.1292,
    #         }
    #       },
    #     ]
    #   }
    # }
    def get_video_results(video_id, *args)
      get("videos/#{video_id}", *args)
    end

    # Registers a new stream on Matroid
    # @param stream_url [String] the url for the stream
    # @param stream_name [String] the name of the stream
    # @return Hash containing the id of the stream { "stream_id" => "123" }
    def register_stream(stream_url, stream_name)
      register_err = "Must include a url and name for stream"
      raise Error::InvalidQueryError.new(register_err) unless stream_url && stream_name
      Matroid.post("feeds", name: stream_name, url: stream_url)
    end


  end
end
