require 'net/http'
require 'uri'
require 'json'
require 'digest'
require_relative './apple_maps_client.rb'

module Jekyll
  module AppleMaps
    class SnapshotBlock < Liquid::Block
      class AppleMapsError < StandardError; end

      @@used_snapshots = Set.new
      @@color_schemes = ['light', 'dark']
      @@log_prefix = "AppleMapsSnapshotBlock:"

      def initialize(tag_name, markup, options)
        super

        api_key = ENV['APPLE_MAPS_SNAPSHOT_API_KEY']
        unless api_key
          log_and_raise("Apple Maps API key not found")
        end
        @client = AppleMapsClient.new(api_key)
      end

      def render(context)
        content = super
        params = YAML.safe_load(content)
        width = params['width'] || 600
        height = params['height'] || 300
        size = "#{width}x#{height}"
        annotations = params['annotations'] || []
        overlays = params['overlays'] || []
        overlay_styles = params['overlay_styles'] || []
        images = params['images'] || []
        color_schemes = params['color_schemes'] || ['light', 'dark']
        show_poi = params['show_poi'] || true ? 1 : 0

        if color_schemes.empty?
          log_and_raise("Color Schemes cannot be empty")
        end

        query = {
          center: params['center'] || 'auto',
          annotations: annotations.to_json,
          overlays: overlays.to_json,
          overlayStyles: overlay_styles.to_json,
          imgs: images.to_json,
          size: size,
          z: params['zoom'] || 12,
          t: params['map_type'] || 'standard',
          scale: params['scale'] || 2,
          lang: params['language'] || 'en-US',
          spn: params['span'] || nil,
          poi: show_poi,
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
        hash = Digest::SHA256.hexdigest(query.to_s)
        filename = "apple_maps_snapshot_#{hash}.png"
        relative_path = "assets/maps/#{filename}"
        full_path = File.join(context.registers[:site].source, relative_path)

        @@used_snapshots.add(filename)

        if File.exist?(full_path)
          return relative_path
        end

        Jekyll.logger.info @@log_prefix, "Fetching new snapshot from Apple Maps API"
        image_data = @client.fetch_snapshot(query)

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
