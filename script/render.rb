#!/usr/bin/env ruby

require 'jekyll'
require 'liquid'
require 'optparse'
require_relative '../lib/jekyll/apple_maps/snapshot_block'

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

  opts.on("-s", "--source DIR", "Specify the source DIR") do |dir|
    options[:source] = dir
  end

  opts.on("-r", "--referer URL", "Specify the referer URL") do |url|
    options[:referer] = url
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# Check for required options
if options[:source].nil? || options[:referer].nil?
  puts "Error: Both source directory (-s) and referer URL (-r) are required."
  puts "Use -h or --help for usage information."
  exit 1
end

# Mock site and context
class MockSite < Jekyll::Site
  attr_reader :source, :config

  def initialize(source, referer)
    @config = Jekyll.configuration({'source' => source})
    @config['apple_maps'] = { 'referer' => referer } if referer
    super(@config)
    @static_files = []
    @source = source
  end
end

site = MockSite.new(options[:source], options[:referer])
context = Liquid::Context.new({}, {}, { site: site }, { strict_variables: true, strict_filters: true })

# Register the custom tag
Liquid::Template.register_tag('apple_maps_snapshot_block', Jekyll::AppleMaps::SnapshotBlock)

puts "Enter your Apple Maps Snapshot template (press Ctrl+D when finished):"
template = STDIN.read

begin
  # Parse the entire template
  template = Liquid::Template.parse(template)

  # Render the template
  result = template.render(context)

  puts "\nRendered output:"
  puts result
rescue => e
  puts "\nError occurred:"
  puts e.message
  puts e.backtrace.join("\n")
end

puts "\nSite source directory: #{site.source}"
puts "Apple Maps referer: #{site.config.dig('apple_maps', 'referer') || ''}"
