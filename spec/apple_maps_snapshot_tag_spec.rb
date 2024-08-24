require 'spec_helper'
require 'jekyll'
require 'pry'
require 'fakefs/safe'
require_relative '../lib/jekyll/apple-maps/snapshot_block'

RSpec.describe Jekyll::AppleMaps::SnapshotBlock do
  let(:template) {
    <<~TEMPLATE
    center: "auto"
    show_poi: true
    zoom: 14
    width: 600
    height: 150
    annotations: [
      {
        "point": "33.24767,115.73192",
        "color":"449944",
        "glyphText": "Salton Sea",
        "markerStyle": "large"
      }
    ]
    {% endapple_maps_snapshot_block %}
    TEMPLATE
  }
  let(:tokenizer) { Liquid::Tokenizer.new(template) }
  let(:tag_name) { 'apple_maps_snapshot_block' }
  let(:page) { make_page }
  let(:render_context) { make_context(:page => page, :site => site) }
  let(:parse_context) { Liquid::ParseContext.new }
  let(:context) { Liquid::Context.new({}, {}, { site: site }, { strict_variables: true, strict_filters: true }) }
  let(:image_content) { "Good image content" }
  let(:api_key) { "apple maps api key" }
  let(:site) { instance_double(Jekyll::Site, source: '/tmp/test_site') }
  let(:client) { instance_double(Jekyll::AppleMaps::AppleMapsClient) }

  let(:rendered) { subject.render(render_context) }
  let(:payload) { subject.send(:payload) }

  let(:site_source) { '/tmp/test_site' }
  let(:maps_dir) { File.join(site_source, 'assets', 'maps') }

  before do
    FakeFS.clear!
    FakeFS.activate!
    ENV['APPLE_MAPS_SNAPSHOT_API_KEY'] = api_key
    FileUtils.mkdir_p(maps_dir)
    allow(site).to receive(:source).and_return(site_source)
    allow(site).to receive(:static_files).and_return([])

    allow(Jekyll::AppleMaps::AppleMapsClient).to receive(:new).with(api_key).and_return(client)
    allow(client).to receive(:fetch_snapshot).and_return(image_content)
  end

  after do
    FakeFS.deactivate!
  end

  subject do
    tag = described_class.parse(tag_name, {}, tokenizer, parse_context)
    tag.instance_variable_set("@context", context)
    tag
  end

  describe '#render' do
    context 'with light and dark mode' do
      it 'generates a picture tag' do
        expected_params = {
          :annotations=>"[{\"point\":\"33.24767,115.73192\",\"color\":\"449944\",\"glyphText\":\"Salton Sea\",\"markerStyle\":\"large\"}]",
          :center=>"auto",
          :imgs=>"[]",
          :lang=>"en-US",
          :overlayStyles=>"[]",
          :overlays=>"[]",
          :poi=>1,
          :scale=>2,
          :size=>"600x150",
          :t=>"standard",
          :z=>14
        }

        expect(client).to receive(:fetch_snapshot)
          .with(expected_params.merge({:colorScheme => 'dark'}))
          .once
        expect(client).to receive(:fetch_snapshot)
          .with(expected_params.merge({:colorScheme => 'light'}))
          .once
        rendered_content = subject.render(context)

        expect(rendered_content).to eq("<picture><source srcset='/assets/maps/apple_maps_snapshot_72371e4c60df063e0bfa66136639392ddaae749743afbf4440b9998405ebeb2a.png' media='(prefers-color-scheme: light)'><source srcset='/assets/maps/apple_maps_snapshot_d8c698f67c560f562a3c46f07199bea93cf10c53832f60281725e4a58118cd6c.png' media='(prefers-color-scheme: dark)'><img src='/[\"light\", \"assets/maps/apple_maps_snapshot_72371e4c60df063e0bfa66136639392ddaae749743afbf4440b9998405ebeb2a.png\"]' alt='Map of location'></picture>")

        # Check if files were created
        expect(Dir.glob(File.join(maps_dir, 'apple_maps_snapshot_*.png')).length).to eq(2)

        # Check file contents
        Dir.glob(File.join(maps_dir, 'apple_maps_snapshot_*.png')).each do |file|
          expect(File.read(file)).to eq(image_content)
        end
      end
    end

    it 'raises an error when API key is missing' do
      ENV['APPLE_MAPS_SNAPSHOT_API_KEY'] = nil
      expect { subject.render(context) }.to raise_error(Jekyll::AppleMaps::SnapshotBlock::AppleMapsError, /Apple Maps API key not found/)
    end
  end
end
