require "matroid/version"
require 'httparty'
require 'pry'

module Matroid
  class MatroidClient
    def initialize(options)
      @base_url = options[:base_url]
      @client_id = options[:client_id]
      @client_secret = options[:client_secret]
      @request = HTTParty

      @endpoints = {
        token: { method: :post, uri: "#{@base_url}/oauth/token" },
        account_info: { method: :get, uri: "#{@base_url}/account" }
      }
    end

    def retrieve_token
      endpoint = @endpoints[:token]
      opts = {
        body: {
          client_id: @client_id,
          client_secret: @client_secret,
          grant_type: 'client_credentials'
        }
      }
      response = @request.send(endpoint[:method], endpoint[:uri], opts)
      @authorization_header = "#{response['token_type']} #{response['access_token']}"
      response.parsed_response
    end

    def account_info
      endpoint = @endpoints[:account_info]
      headers = { "Authorization" => @authorization_header }
      opts = {
        headers: headers
      }
      response = @request.send(endpoint[:method], endpoint[:uri], opts)
      response.parsed_response
    end
  end
end
