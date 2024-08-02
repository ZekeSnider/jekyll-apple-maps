require 'net/http'
require 'uri'
require 'json'
require 'digest'

module Jekyll
  module AppleMaps
    class SnapshotBlock < Liquid::Block
      class AppleMapsError < StandardError; end

      @@used_snapshots = Set.new
      @@color_schemes = ['light', 'dark']
      @@log_prefix = "AppleMapsSnapshotBlock:"

      def initialize(tag_name, markup, options)
        super
      end

      def render(context)
        Jekyll.logger.info @@log_prefix, "Rendering map snapshot"

        content = super
        params = YAML.safe_load(content)
        center = params['center'] || 'auto'
        width = params['width'] || 600
        height = params['height'] || 300
        annotations = params['annotations'] || []
        overlays = params['overlays'] || []
        overlay_styles = params['overlay_styles'] || []
        images = params['images'] || []
        map_type = params['map_type'] || 'standard'
        color_schemes = params['colorSchemes'] || ['light', 'dark']
        language = params['language'] || 'en-US'
        span = params['span'] || nil
        api_key = ENV['APPLE_MAPS_API_KEY']

        unless api_key
          log_and_raise("Apple Maps API key not found")
        end

        if color_schemes.empty?
          log_and_raise("Color Schemes cannot be empty")
        end

        query = {
          center: center,
          annotations: annotations.to_json,
          overlays: overlays.to_json,
          overlayStyles: overlay_styles.to_json,
          imgs: images.to_json,
          size: "#{width}x#{height}",
          z: params['zoom'] || 12,
          t: map_type,
          scale: params['scale'] || 2,
          poi: params['show_poi'] || 1,
          lang: language,
          spn: span,
          token: api_key
        }
        query.compact!

        image_relative_paths = color_schemes.to_h do |color_scheme|
          query[:colorScheme] = color_scheme
          [color_scheme, get_relative_path(context, query)]
        end

        result_tag = "<picture>"
        image_relative_paths.each do |color_scheme, relative_path|
          result_tag << "<source srcset='/#{relative_path}' media='(prefers-color-scheme: #{color_scheme})'>"
        end
        result_tag << "<img src='/#{image_relative_paths.first}' alt='Map of location'>"
        result_tag << "</picture>"

        Jekyll.logger.info @@log_prefix, "Generated picture tag with #{color_schemes.size} color schemes"
        return result_tag
      end

      def self.cleanup(site)
        Jekyll.logger.info @@log_prefix, "Starting cleanup of unused snapshots"

        maps_dir = File.join(site.source, 'assets', 'maps')
        return unless File.directory?(maps_dir)

        Dir.glob(File.join(maps_dir, 'apple_maps_snapshot_*.png')).each do |file|
          filename = File.basename(file)
          unless @@used_snapshots.include?(filename)
            File.delete(file)
            Jekyll.logger.info @@log_prefix, "Deleted unused map snapshot: #{filename}"
          end
        end

        Jekyll.logger.info @@log_prefix, "Cleanup completed"
      end

      private

      def get_relative_path(context, query)
        url = "https://snapshot.apple-mapkit.com/api/v1/snapshot"
        hash = Digest::SHA256.hexdigest(query.to_s)
        uri = URI(url)
        uri.query = URI.encode_www_form(query)
        filename = "apple_maps_snapshot_#{hash}.png"
        relative_path = "assets/maps/#{filename}"
        full_path = File.join(context.registers[:site].source, relative_path)

        @@used_snapshots.add(filename)

        if File.exist?(full_path)
          Jekyll.logger.info @@log_prefix, "Using existing snapshot: #{filename}"
          return relative_path
        end

        Jekyll.logger.info @@log_prefix, "Fetching new snapshot from Apple Maps API"
        response = Net::HTTP.get_response(uri)
        if !response.is_a?(Net::HTTPSuccess)
          log_and_raise("Failed to generate map snapshot. Response: #{response.body}, Query: #{query}")
        end

        image_data = response.body
        FileUtils.mkdir_p(File.dirname(full_path))
        static_file = Jekyll::StaticFile.new(context.registers[:site], context.registers[:site].source,
          File.dirname(relative_path), filename)
        FileUtils.mkdir_p(File.dirname(static_file.path))
        File.open(static_file.path, 'wb') do |file|
          file.write(image_data)
        end
        context.registers[:site].static_files << static_file

        return relative_path
      end

      def log_and_raise(message)
        Jekyll.logger.error @@log_prefix, message
        raise AppleMapsError, message
      end
    end
  end
end

Liquid::Template.register_tag('apple_maps_snapshot_block', Jekyll::AppleMaps::SnapshotBlock)

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::AppleMaps::SnapshotBlock.cleanup(site)
end
