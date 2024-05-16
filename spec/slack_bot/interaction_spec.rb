require "spec_helper"

describe SlackBot::Interaction do
  subject { described_class.new(current_user: current_user, params: params, callback: callback, config: config) }

  let(:current_user) { double("current_user") }
  let(:params) { {} }
  let(:callback) { instance_double(SlackBot::Callback, id: "test-callback-id") }
  let(:config) { instance_double(SlackBot::Config) }

  before do
    allow(callback).to receive(:view_id=).and_return(nil)
    allow(callback).to receive(:save).and_return(nil)
  end

  it "initializes" do
    expect(subject.current_user).to eq(current_user)
    expect(subject.params).to eq(params)
    expect(subject.callback).to eq(callback)
    expect(subject.config).to eq(config)
  end

  describe ".open_modal" do
    subject(:open_modal) { described_class.open_modal(callback: callback, trigger_id: trigger_id, view: view) }

    let(:trigger_id) { "trigger_id" }
    let(:view) { {} }
    let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {"id" => "view_id"}}) }

    before do
      allow(SlackBot::ApiClient).to receive(:new).and_return(instance_double(SlackBot::ApiClient, views_open: response))
    end

    it "opens modal" do
      expect(open_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, "view_id"))
    end

    context "when response is not ok" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: false, error: "error", data: {"view" => {"id" => "view_id"}}) }

      it "raises error" do
        expect { open_modal }.to raise_error(SlackBot::Errors::OpenModalError)
      end
    end
  end

  describe ".update_modal" do
    subject(:update_modal) { described_class.update_modal(callback: callback, view_id: view_id, view: view) }

    let(:view_id) { "view_id" }
    let(:view) { {} }
    let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {"id" => "view_id"}}) }

    before do
      allow(SlackBot::ApiClient).to receive(:new).and_return(instance_double(SlackBot::ApiClient, views_update: response))
    end

    it "updates modal" do
      expect(update_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, "view_id"))
    end

    context "when response is not ok" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: false, error: "error", data: {"view" => {"id" => "view_id"}}) }

      it "raises error" do
        expect { update_modal }.to raise_error(SlackBot::Errors::UpdateModalError)
      end
    end
  end

  describe ".publish_view" do
    subject(:publish_view) { described_class.publish_view(callback: callback, metadata: metadata, user_id: user_id, view: view) }

    let(:user_id) { "user_id" }
    let(:metadata) { "metadata" }
    let(:view) { {} }
    let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {"id" => "view_id"}}) }

    before do
      allow(SlackBot::ApiClient).to receive(:new).and_return(instance_double(SlackBot::ApiClient, views_publish: response))
    end

    it "publishes view" do
      expect(publish_view).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, "view_id"))
    end

    context "when response is not ok" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: false, error: "error", data: {"view" => {"id" => "view_id"}}) }

      it "raises error" do
        expect { publish_view }.to raise_error(SlackBot::Errors::PublishViewError)
      end
    end
  end
end
