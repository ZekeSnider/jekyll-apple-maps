require 'spec_helper'
require 'jekyll'
require 'pry'
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
  let(:site) { instance_double(Jekyll::Site, source: '/tmp/test_site') }
  let(:tokenizer) { Liquid::Tokenizer.new(template) }
  let(:rendered) { subject.render(render_context) }
  let(:payload) { subject.send(:payload) }

  before do
    ENV['APPLE_MAPS_SNAPSHOT_API_KEY'] = 'test_api_key'
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
        allow(subject).to receive(:get_relative_path).and_return('assets/maps/test_snapshot.png')

        rendered_content = subject.render(context)
        expect(rendered_content).to eq([
          "<picture>",
          "<source srcset='/assets/maps/test_snapshot.png' media='(prefers-color-scheme: light)'>",
          "<source srcset='/assets/maps/test_snapshot.png' media='(prefers-color-scheme: dark)'>",
          "<img src='/[\"light\", \"assets/maps/test_snapshot.png\"]' alt='Map of location'>",
          "</picture>"
        ].join)
      end
    end

    it 'raises an error when API key is missing' do
      ENV['APPLE_MAPS_SNAPSHOT_API_KEY'] = nil
      expect { subject.render(context) }.to raise_error(Jekyll::AppleMaps::SnapshotBlock::AppleMapsError, /Apple Maps API key not found/)
    end
  end
end
