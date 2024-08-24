require 'net/http'
require 'uri'
require 'json'
require 'digest'

module Jekyll
  module AppleMaps
    class AppleMapsClient
      class AppleMapsNetworkError < StandardError; end

      @@snapshot_base_url = "https://snapshot.apple-mapkit.com/api/v1/snapshot"

      def initialize(api_key)
        @api_key = api_key
      end

      def fetch_snapshot(query)
        query[:token] = @api_key
        uri = URI(@@snapshot_base_url)
        uri.query = URI.encode_www_form(query)

        response = Net::HTTP.get_response(uri)
        unless response.is_a?(Net::HTTPSuccess)
          raise AppleMapsNetworkError, "Failed to generate map snapshot. Response: #{response.body}, Query: #{query}"
        end

        response.body
      end
    end
  end
end
