require 'spec_helper'
require 'webmock/rspec'
require 'pry'
require_relative '../lib/jekyll/apple-maps/apple_maps_client.rb'

RSpec.describe Jekyll::AppleMaps::AppleMapsClient do
  let(:api_key) { 'snapshot_api_key' }
  let(:base_url) { "https://snapshot.apple-mapkit.com/api/v1/snapshot" }
  let(:query) do
    {
      "width" => 200,
      "height" => 600
    }
  end
  let(:response) { "image data" }
  let(:response_code) { 200 }

  subject do
    described_class.new(api_key)
  end

  before do
    stub_request(:get, base_url)
      .with(query: hash_including({}))
      .to_return(status: response_code, body: response, headers: {})
  end

  describe '#fetch_snapshot' do
    context 'with a succesful response' do
      it 'fetches a snapshot' do
        exepcted_query_params = {
          "width" => "200",
          "height" => "600",
          "token" => api_key
        }
        expect(subject.fetch_snapshot(query)).to eq(response)
        expect(WebMock).to have_requested(:get, base_url)
          .with(query: exepcted_query_params)
          .once
      end
    end

    context 'with a failure response' do
      let(:response_code) { 400 }

      it 'raises an exception' do
        exepcted_query_params = {
          "width" => "200",
          "height" => "600",
          "token" => api_key
        }
        expect{ subject.fetch_snapshot(query) }.to raise_error(an_instance_of(Jekyll::AppleMaps::AppleMapsClient::AppleMapsNetworkError))
        expect(WebMock).to have_requested(:get, base_url)
          .with(query: exepcted_query_params)
          .once
      end
    end
  end
end
