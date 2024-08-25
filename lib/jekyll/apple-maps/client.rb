require 'net/http'
require 'uri'
require 'json'
require 'digest'

module Jekyll
  module AppleMaps
    class AppleMapsClient
      class AppleMapsNetworkError < StandardError; end

      @@snapshot_base_url = "https://snapshot.apple-mapkit.com/api/v1/snapshot"
      @@snapshot_uri = URI(@@snapshot_base_url)

      def initialize(api_key)
        @api_key = api_key
      end

      def fetch_snapshot(query, referer)
        query[:token] = @api_key
        uri = @@snapshot_uri.dup
        uri.query = URI.encode_www_form(query)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri)
        request['referer'] = referer
        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise AppleMapsNetworkError, "Failed to generate map snapshot. Response: #{response.body}, Query: #{query}"
        end

        response.body
      end
    end
  end
end
