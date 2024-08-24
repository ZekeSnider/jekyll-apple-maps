require 'spec_helper'
require 'jekyll'
require 'pry'
require 'fakefs/safe'
require_relative '../lib/jekyll/apple-maps/snapshot_block'

RSpec.describe Jekyll::AppleMaps::SnapshotBlock do
  let(:template) {
    <<~TEMPLATE
    center: {{ include.coordinates }}
    show_poi: true
    zoom: 14
    width: 600
    height: 150
    annotations: [
      {
        "point": "{{ include.coordinates }}",
        "color":"449944",
        "glyphText": "{{ include.title | slice: 0 }}",
        "markerStyle":"large"
      }
    ]
    {% endapple_maps_snapshot_block %}
    TEMPLATE
  }
  let(:tag_name) { 'apple_maps_snapshot_block' }
  let(:markup) { "{% #{tag_name} %} #{params} {% end#{tag_name} %}" }
  let(:page) { make_page }
  let(:render_context) { make_context(:page => page, :site => site) }
  let(:parse_context) { Liquid::ParseContext.new }
  let(:context) do
    Liquid::Context.new(
      {},
      {},
      { site: site },
      { strict_variables: true, strict_filters: true }
    )
  end
  let(:image_content) { "Good image content" }
  let(:site) { instance_double(Jekyll::Site, source: '/tmp/test_site') }
  let(:client) { instance_double(Jekyll::AppleMaps::AppleMapsClient) }
  let(:tokenizer) { Liquid::Tokenizer.new(template) }
  let(:rendered) { subject.render(render_context) }
  let(:payload) { subject.send(:payload) }
  let(:site_source) { '/tmp/test_site' }
  let(:maps_dir) { File.join(site_source, 'assets', 'maps') }

  before do
    FakeFS.clear!
    FakeFS.activate!
    ENV['APPLE_MAPS_SNAPSHOT_API_KEY'] = 'test_api_key'
    FileUtils.mkdir_p(maps_dir)
    allow(site).to receive(:source).and_return(site_source)
    allow(site).to receive(:static_files).and_return([])

    allow(Jekyll::AppleMaps::AppleMapsClient)
      .to receive(:new)
      .and_return(client)
    allow(client).to receive(:fetch_snapshot).and_return(image_content)
  end

  after do
    FakeFS.deactivate!
  end

  subject do
    tag = described_class.parse(tag_name, markup, tokenizer, parse_context)
    tag.instance_variable_set("@context", context)
    tag
  end

  describe '#render' do
    let(:params) { "" }

    context 'with a basic template' do
      it 'generates a picture tag' do
        expect(client).to receive(:fetch_snapshot).twice
        rendered_content = subject.render(context)


        # expect(rendered_content).to eq([
        #   "<picture>",
        #   "<source srcset='assets/maps/apple_maps_snapshot_4a8fa7d439218e740d600ce22fee960ad15ed83e67f3e4e148362bc56d0e6968.png' media='(prefers-color-scheme: light)'>",
        #   "<source srcset='/assets/maps/apple_maps_snapshot_d5015b970d1e804631d1fb750c5b43f6c7b58d0272deed29c40946e95c4b55fb.png' media='(prefers-color-scheme: dark)'>",
        #   "<img src='/[\"light\", \"assets/maps/apple_maps_snapshot_4a8fa7d439218e740d600ce22fee960ad15ed83e67f3e4e148362bc56d0e6968.png\"]' alt='Map of location'>",
        #   "</picture>"
        # ].join)

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
