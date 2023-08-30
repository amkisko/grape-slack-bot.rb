require 'spec_helper'

describe SlackBot::Event do
  let(:current_user) { double(:current_user) }
  let(:params) { double(:params) }
  let(:callback) { double(:callback) }
  let(:config) { double(:config) }

  subject do
    described_class.new(
      current_user: current_user,
      params: params,
      callback: callback,
      config: config
    )
  end

  describe '.view_klass' do
    it 'raises exception' do
      expect { subject.class.view_klass }.to raise_error(SlackBot::Errors::ViewClassNotImplemented)
    end

    context "when view is called" do
      before do
        subject.class.view :view_name
      end
      it 'returns view_name' do
        expect(subject.class.view_klass).to eq(:view_name)
      end
    end
  end

  describe '.interaction_klass' do
    it 'raises exception' do
      expect { subject.class.interaction_klass }.to raise_error(SlackBot::Errors::InteractionClassNotImplemented)
    end
    context "when interaction is called" do
      before do
        subject.class.interaction :interaction_name
      end
      it 'returns interaction_name' do
        expect(subject.class.interaction_klass).to eq(:interaction_name)
      end
    end
  end

  describe '#initialize' do
    it 'sets current_user' do
      expect(subject.current_user).to eq(current_user)
    end

    it 'sets params' do
      expect(subject.params).to eq(params)
    end

    it 'sets callback' do
      expect(subject.callback).to eq(callback)
    end

    it 'sets config' do
      expect(subject.config).to eq(config)
    end
  end

  describe '#call' do
    it 'returns nil' do
      expect(subject.call).to eq(nil)
    end
  end

  describe '#publish_view' do

  end
end
