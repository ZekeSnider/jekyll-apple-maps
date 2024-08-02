require 'spec_helper'
require 'jekyll'
require 'pry'
require_relative '../lib/jekyll/apple-maps/snapshot_block'

RSpec.describe Jekyll::AppleMaps::SnapshotBlock do
  let(:tag_name) { 'apple_maps_snapshot_block' }
  let(:template) {
    <<~TEMPLATE
    center: {{ include.coordinates }}
    show_poi: 1
    zoom: 14
    width: 600
    height: 150f
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
    ENV['APPLE_MAPS_API_KEY'] = 'test_api_key'
  end

  subject do
    tag = described_class.parse(tag_name, markup, tokenizer, parse_context)
    tag.instance_variable_set("@context", context)
    tag
  end

  describe '#render' do
    let(:params) { "" }

    it 'generates a picture tag with multiple sources' do
      allow(subject).to receive(:get_relative_path).and_return('assets/maps/test_snapshot.png')

      rendered_content = subject.render(context)

      expect(rendered_content).to include('<picture>')
      expect(rendered_content).to include("<source srcset='/assets/maps/test_snapshot.png' media='(prefers-color-scheme: light)'>")
      expect(rendered_content).to include("<source srcset='/assets/maps/test_snapshot.png' media='(prefers-color-scheme: dark)'>")
      expect(rendered_content).to include("<img src='/assets/maps/test_snapshot.png' alt='Map of location'>")
      expect(rendered_content).to include('</picture>')
    end

    # it 'raises an error when API key is missing' do
    #   ENV['APPLE_MAPS_API_KEY'] = nil
    #   expect { block.render(context) }.to raise_error(Jekyll::AppleMaps::SnapshotBlock::AppleMapsError, /Apple Maps API key not found/)
    # end

    # it 'raises an error when color schemes are empty' do
    #   allow(YAML).to receive(:safe_load).and_return({ 'colorSchemes' => [] })
    #   expect { block.render(context) }.to raise_error(Jekyll::AppleMaps::SnapshotBlock::AppleMapsError, /Color Schemes cannot be empty/)
    # end
  end
end
