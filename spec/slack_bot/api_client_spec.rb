require "spec_helper"

describe SlackBot::ApiClient do
  subject(:client) { described_class.new(authorization_token: authorization_token) }
  let(:authorization_token) { "test_authorization_token" }

  it "does not raise errors" do
    expect { client }.not_to raise_error
  end

  context "when the authorization token is not set" do
    let(:authorization_token) { nil }
    it "raises SlackApiError" do
      expect { client }.to raise_error(SlackBot::Errors::SlackApiError, "Slack bot API token is not set")
    end
  end

  context "when the authorization token is empty string" do
    let(:authorization_token) { "" }
    it "raises SlackApiError" do
      expect { client }.to raise_error(SlackBot::Errors::SlackApiError, "Slack bot API token is not set")
    end
  end

  context "when the authorization token is not a string" do
    let(:authorization_token) { 123 }
    it "raises SlackApiError" do
      expect { client }.to raise_error(SlackBot::Errors::SlackApiError, "Slack bot API token is not set")
    end
  end

  describe "#users_info" do
    before do
      stub_request(:post, "https://slack.com/api/users.info").to_return(response)
    end
    subject(:users_info) { client.users_info(user_id: user_id) }
    let(:user_id) { "U0R7JM" }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "user" => {
            "id" => "W012A3CDE",
            "team_id" => "T012AB3C4",
            "name" => "spengler",
            "deleted" => false,
            "color" => "9f69e7",
            "real_name" => "Egon Spengler",
            "tz" => "America/Los_Angeles",
            "tz_label" => "Pacific Daylight Time",
            "tz_offset" => -25200,
            "profile" => {
              "avatar_hash" => "ge3b51ca72de",
              "status_text" => "Print is dead",
              "status_emoji" => ":books:",
              "real_name" => "Egon Spengler",
              "display_name" => "spengler",
              "real_name_normalized" => "Egon Spengler",
              "display_name_normalized" => "spengler",
              "email" => "spengler@ghostbusters.example.com",
              "image_original" => "https://.../avatar/e3b51ca72dee4ef87916ae2b9240df50.jpg",
              "image_24" => "https://.../avatar/e3b51ca72dee4ef87916ae2b9240df50.jpg",
              "image_32" => "https://.../avatar/e3b51ca72dee4ef87916ae2b9240df50.jpg",
              "image_48" => "https://.../avatar/e3b51ca72dee4ef87916ae2b9240df50.jpg",
              "image_72" => "https://.../avatar/e3b51ca72dee4ef87916ae2b9240df50.jpg",
              "image_192" => "https://.../avatar/e3b51ca72dee4ef87916ae2b9240df50.jpg",
              "image_512" => "https://.../avatar/e3b51ca72dee4ef87916ae2b9240df50.jpg",
              "team" => "T012AB3C4"
            },
            "is_admin" => true,
            "is_owner" => false,
            "is_primary_owner" => false,
            "is_restricted" => false,
            "is_ultra_restricted" => false,
            "is_bot" => false,
            "updated" => 1502138686,
            "is_app_user" => false,
            "has_2fa" => false
          }
        }.to_json
      }
    }
    it "sends authorization token" do
      expect(users_info.response.env.request_headers["Authorization"]).to eq("Bearer #{authorization_token}")
    end
    it "returns a successful response" do
      expect(users_info.ok?).to eq(true)
    end
    context "when the response is not successful" do
      let(:response) {
        {
          status: 200,
          body: {
            "ok" => false,
            "error" => "user_not_found"
          }.to_json
        }
      }
      it "returns an unsuccessful response" do
        expect(users_info.ok?).to eq(false)
      end
    end
  end

  describe "#views_open" do
    before do
      stub_request(:post, "https://slack.com/api/views.open").to_return(response)
    end
    subject(:views_open) {
      client.views_open(
        trigger_id: "trigger_id",
        view: {
          "type" => "modal",
          "title" => {
            "type" => "plain_text",
            "text" => "Quite a plain modal"
          },
          "submit" => {
            "type" => "plain_text",
            "text" => "Create"
          },
          "blocks" => [
            {
              "type" => "input",
              "block_id" => "a_block_id",
              "label" => [
                "type" => "plain_text",
                "text" => "A simple label",
                "emoji" => true
              ],
              "optional" => false,
              "element" => {
                "type" => "plain_text_input",
                "action_id" => "an_action_id"
              }
            }
          ]
        }
      )
    }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "view" => {
            "id" => "VMHU10V25",
            "team_id" => "T8N4K1JN",
            "type" => "modal",
            "title" => {
              "type" => "plain_text",
              "text" => "Quite a plain modal"
            },
            "submit" => {
              "type" => "plain_text",
              "text" => "Create"
            },
            "blocks" => [
              {
                "type" => "input",
                "block_id" => "a_block_id",
                "label" => {
                  "type" => "plain_text",
                  "text" => "A simple label",
                  "emoji" => true
                },
                "optional" => false,
                "element" => {
                  "type" => "plain_text_input",
                  "action_id" => "an_action_id"
                }
              }
            ],
            "private_metadata" => "Shh it is a secret",
            "callback_id" => "identify_your_modals",
            "external_id" => "",
            "state" => {
              "values" => {}
            },
            "hash" => "156772938.1827394",
            "clear_on_close" => false,
            "notify_on_close" => false,
            "root_view_id" => "VMHU10V25",
            "app_id" => "AA4928AQ",
            "bot_id" => "BA13894H"
          }
        }.to_json
      }
    }
    it "returns a successful response" do
      expect(views_open.ok?).to eq(true)
    end

    context "when the response is unsuccessful" do
      let(:response) {
        {
          status: 200,
          body: {
            "ok" => false,
            "error" => "invalid_arguments",
            "response_metadata" => {
              "messages" => [
                "invalid `trigger_id`"
              ]
            }
          }.to_json
        }
      }
      it "returns an unsuccessful response" do
        expect(views_open.ok?).to eq(false)
      end
    end
  end

  describe "#views_update" do
    before do
      stub_request(:post, "https://slack.com/api/views.update").to_return(response)
    end
    subject(:views_update) {
      client.views_update(
        view_id: "VMHU10V25",
        view: {
          "type" => "modal",
          "title" => {
            "type" => "plain_text",
            "text" => "Quite a plain modal"
          },
          "submit" => {
            "type" => "plain_text",
            "text" => "Create"
          },
          "blocks" => [
            {
              "type" => "input",
              "block_id" => "a_block_id",
              "label" => [
                "type" => "plain_text",
                "text" => "A simple label",
                "emoji" => true
              ],
              "optional" => false,
              "element" => {
                "type" => "plain_text_input",
                "action_id" => "an_action_id"
              }
            }
          ]
        }
      )
    }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "view" => {
            "id" => "VMHU10V25",
            "team_id" => "T8N4K1JN",
            "type" => "modal",
            "title" => {
              "type" => "plain_text",
              "text" => "Quite a plain modal"
            },
            "submit" => {
              "type" => "plain_text",
              "text" => "Create"
            },
            "blocks" => [
              {
                "type" => "input",
                "block_id" => "a_block_id",
                "label" => {
                  "type" => "plain_text",
                  "text" => "A simple label",
                  "emoji" => true
                },
                "optional" => false,
                "element" => {
                  "type" => "plain_text_input",
                  "action_id" => "an_action_id"
                }
              }
            ],
            "private_metadata" => "Shh it is a secret",
            "callback_id" => "identify_your_modals",
            "external_id" => "",
            "state" => {
              "values" => {}
            },
            "hash" => "156772938.1827394",
            "clear_on_close" => false,
            "notify_on_close" => false,
            "root_view_id" => "VMHU10V25",
            "app_id" => "AA4928AQ",
            "bot_id" => "BA13894H"
          }
        }.to_json
      }
    }
    it "returns a successful response" do
      expect(views_update.ok?).to eq(true)
    end
    context "when the response is unsuccessful" do
      let(:response) {
        {
          status: 200,
          body: {
            "ok" => false,
            "error" => "invalid_arguments",
            "response_metadata" => {
              "messages" => [
                "invalid `trigger_id`"
              ]
            }
          }.to_json
        }
      }
      it "returns an unsuccessful response" do
        expect(views_update.ok?).to eq(false)
      end
    end
  end

  describe "#chat_post_message" do
    before do
      stub_request(:post, "https://slack.com/api/chat.postMessage").to_return(response)
    end
    subject(:chat_post_message) {
      client.chat_post_message(
        channel: "C1234567890",
        text: "Hello world",
        blocks: [
          {
            "type" => "section",
            "text" => {
              "type" => "mrkdwn",
              "text" => "Hello world"
            }
          }
        ]
      )
    }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "channel" => "C1234567890",
          "ts" => "1503435956.000247",
          "message" => {
            "text" => "Hello world",
            "username" => "ecto1",
            "bot_id" => "B19LU7CSY",
            "attachments" => [
              {
                "text" => "This is an attachment",
                "id" => 1,
                "fallback" => "This is an attachment's fallback"
              }
            ],
            "type" => "message",
            "subtype" => "bot_message",
            "ts" => "1503435956.000247"
          }
        }.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_post_message.ok?).to eq(true)
    end
    context "when the response is unsuccessful" do
      let(:response) {
        {
          status: 200,
          body: {
            "ok" => false,
            "error" => "too_many_attachments"
          }.to_json
        }
      }
      it "returns an unsuccessful response" do
        expect(chat_post_message.ok?).to eq(false)
      end
    end
  end

  describe "#chat_update" do
    before do
      stub_request(:post, "https://slack.com/api/chat.update").to_return(response)
    end
    subject(:chat_update) {
      client.chat_update(
        channel: "C1234567890",
        ts: "1503435956.000247",
        text: "Hello world",
        blocks: [
          {
            "type" => "section",
            "text" => {
              "type" => "mrkdwn",
              "text" => "Hello world"
            }
          }
        ]
      )
    }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "channel" => "C1234567890",
          "ts" => "1503435956.000247",
          "message" => {
            "text" => "Hello world",
            "username" => "ecto1",
            "bot_id" => "B19LU7CSY",
            "attachments" => [
              {
                "text" => "This is an attachment",
                "id" => 1,
                "fallback" => "This is an attachment's fallback"
              }
            ],
            "type" => "message",
            "subtype" => "bot_message",
            "ts" => "1503435956.000247"
          }
        }.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_update.ok?).to eq(true)
    end
    context "when the response is unsuccessful" do
      let(:response) {
        {
          status: 200,
          body: {
            "ok" => false,
            "error" => "too_many_attachments"
          }.to_json
        }
      }
      it "returns an unsuccessful response" do
        expect(chat_update.ok?).to eq(false)
      end
    end
  end

  describe "#views_publish" do
    before do
      stub_request(:post, "https://slack.com/api/views.publish").to_return(response)
    end
    subject(:views_publish) {
      client.views_publish(
        user_id: "U0R7JM",
        view: {
          "type" => "home",
          "blocks" => [
            {
              "type" => "section",
              "text" => {
                "type" => "mrkdwn",
                "text" => "Welcome to your _App's Home_* :tada:"
              }
            },
            {
              "type" => "divider"
            },
            {
              "type" => "section",
              "text" => {
                "type" => "mrkdwn",
                "text" => "This is a section block with a button."
              },
              "accessory" => {
                "type" => "button",
                "text" => {
                  "type" => "plain_text",
                  "text" => "Click Me"
                },
                "action_id" => "button_click"
              }
            }
          ]
        }
      )
    }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "view" => {
            "id" => "VMHU10V25"
          }
        }.to_json
      }
    }
    it "returns a successful response" do
      expect(views_publish.ok?).to eq(true)
    end
    context "when the response is unsuccessful" do
      let(:response) {
        {
          status: 200,
          body: {
            "ok" => false,
            "error" => "invalid_arguments"
          }.to_json
        }
      }
      it "returns an unsuccessful response" do
        expect(views_publish.ok?).to eq(false)
      end
    end
  end

  describe "#chat_post_ephemeral" do
    before do
      stub_request(:post, "https://slack.com/api/chat.postEphemeral").to_return(response)
    end
    subject(:chat_post_ephemeral) {
      client.chat_post_ephemeral(
        channel: "C1234567890",
        user: "U123",
        text: "Hello world"
      )
    }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "message_ts" => "1503435956.000247"
        }.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_post_ephemeral.ok?).to eq(true)
    end

    context "with optional parameters" do
      it "includes optional parameters when provided" do
        stub_request(:post, "https://slack.com/api/chat.postEphemeral").with(
          body: hash_including(
            "channel" => "C1234567890",
            "user" => "U123",
            "text" => "Hello world",
            "as_user" => true,
            "blocks" => [{"type" => "section"}],
            "icon_emoji" => ":smile:",
            "icon_url" => "https://example.com/icon.png",
            "link_names" => true,
            "parse" => "full",
            "thread_ts" => "1503435956.000247",
            "username" => "bot"
          )
        ).to_return(status: 200, body: {"ok" => true}.to_json)

        client.chat_post_ephemeral(
          channel: "C1234567890",
          user: "U123",
          text: "Hello world",
          as_user: true,
          blocks: [{"type" => "section"}],
          icon_emoji: ":smile:",
          icon_url: "https://example.com/icon.png",
          link_names: true,
          parse: "full",
          thread_ts: "1503435956.000247",
          username: "bot"
        )
      end

      it "excludes optional parameters when not provided" do
        stub_request(:post, "https://slack.com/api/chat.postEphemeral").with(
          body: hash_including("channel" => "C1234567890", "user" => "U123")
        ).to_return(status: 200, body: {"ok" => true}.to_json)

        client.chat_post_ephemeral(
          channel: "C1234567890",
          user: "U123",
          text: nil
        )
      end
    end
  end

  describe "#users_list" do
    before do
      stub_request(:post, "https://slack.com/api/users.list").to_return(response)
    end
    subject(:users_list) {
      client.users_list(limit: 100)
    }
    let(:response) {
      {
        status: 200,
        body: {
          "ok" => true,
          "members" => []
        }.to_json
      }
    }
    it "returns a successful response" do
      expect(users_list.ok?).to eq(true)
    end

    context "with optional parameters" do
      it "includes optional parameters when provided" do
        stub_request(:post, "https://slack.com/api/users.list").with(
          body: hash_including(
            "cursor" => "cursor_123",
            "limit" => 200,
            "include_locale" => true,
            "team_id" => "T123"
          )
        ).to_return(status: 200, body: {"ok" => true, "members" => []}.to_json)

        client.users_list(
          cursor: "cursor_123",
          limit: 200,
          include_locale: true,
          team_id: "T123"
        )
      end

      it "excludes optional parameters when not provided" do
        stub_request(:post, "https://slack.com/api/users.list").with(
          body: hash_including("limit" => 200)
        ).to_return(status: 200, body: {"ok" => true, "members" => []}.to_json)

        client.users_list(limit: 200)
      end
    end
  end

  describe "network error handling" do
    before do
      stub_request(:post, "https://slack.com/api/views.open").to_raise(Faraday::ConnectionFailed.new("Connection failed"))
    end

    it "raises SlackApiError on network errors" do
      expect {
        client.views_open(trigger_id: "trigger", view: {})
      }.to raise_error(SlackBot::Errors::SlackApiError, /Network error/)
    end
  end

  describe "JSON parsing error handling" do
    let(:api_response) { instance_double(Faraday::Response, status: 200, body: "invalid json") }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(api_response)
      allow(SlackBot::Logger).to receive(:error)
    end

    it "handles invalid JSON gracefully" do
      response = client.views_open(trigger_id: "trigger", view: {})
      expect(response.ok?).to eq(false)
      expect(response.data["error"]).to eq("invalid_json_response")
    end
  end

  describe "ApiResponse" do
    describe "#ok?" do
      it "returns false when status is not 200" do
        api_response = instance_double(Faraday::Response, status: 500, body: '{"ok":true}')
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(api_response)
        response = client.views_open(trigger_id: "trigger", view: {})
        expect(response.ok?).to eq(false)
      end

      it "returns false when ok is false" do
        api_response = instance_double(Faraday::Response, status: 200, body: '{"ok":false}')
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(api_response)
        response = client.views_open(trigger_id: "trigger", view: {})
        expect(response.ok?).to eq(false)
      end
    end

    describe "#error" do
      it "returns error from data" do
        api_response = instance_double(Faraday::Response, status: 200, body: '{"ok":false,"error":"test_error"}')
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(api_response)
        response = client.views_open(trigger_id: "trigger", view: {})
        expect(response.error).to eq("test_error")
      end
    end
  end

  describe "#chat_delete" do
    before do
      stub_request(:post, "https://slack.com/api/chat.delete").to_return(response)
    end
    subject(:chat_delete) {
      client.chat_delete(channel: "C1234567890", ts: "1503435956.000247")
    }
    let(:response) {
      {
        status: 200,
        body: {"ok" => true}.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_delete.ok?).to eq(true)
    end
  end

  describe "#chat_unfurl" do
    before do
      stub_request(:post, "https://slack.com/api/chat.unfurl").to_return(response)
    end
    subject(:chat_unfurl) {
      client.chat_unfurl(
        channel: "C1234567890",
        ts: "1503435956.000247",
        unfurls: {"https://example.com" => {"text" => "Example"}}
      )
    }
    let(:response) {
      {
        status: 200,
        body: {"ok" => true}.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_unfurl.ok?).to eq(true)
    end

    context "with optional parameters" do
      it "includes optional parameters when provided" do
        stub_request(:post, "https://slack.com/api/chat.unfurl").with(
          body: hash_including(
            "channel" => "C1234567890",
            "ts" => "1503435956.000247",
            "unfurls" => {"https://example.com" => {"text" => "Example"}},
            "source" => "composer",
            "unfurl_id" => "unfurl_123",
            "user_auth_blocks" => [{"type" => "section"}],
            "user_auth_message" => "Please authenticate",
            "user_auth_required" => true,
            "user_auth_url" => "https://example.com/auth"
          )
        ).to_return(status: 200, body: {"ok" => true}.to_json)

        client.chat_unfurl(
          channel: "C1234567890",
          ts: "1503435956.000247",
          unfurls: {"https://example.com" => {"text" => "Example"}},
          source: "composer",
          unfurl_id: "unfurl_123",
          user_auth_blocks: [{"type" => "section"}],
          user_auth_message: "Please authenticate",
          user_auth_required: true,
          user_auth_url: "https://example.com/auth"
        )
      end
    end
  end

  describe "#chat_schedule_message" do
    before do
      stub_request(:post, "https://slack.com/api/chat.scheduleMessage").to_return(response)
    end
    subject(:chat_schedule_message) {
      client.chat_schedule_message(
        channel: "C1234567890",
        text: "Hello world",
        post_at: 1503435956
      )
    }
    let(:response) {
      {
        status: 200,
        body: {"ok" => true, "scheduled_message_id" => "Q1234567890", "post_at" => 1503435956}.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_schedule_message.ok?).to eq(true)
    end

    context "with blocks parameter" do
      it "includes blocks when provided" do
        stub_request(:post, "https://slack.com/api/chat.scheduleMessage").with(
          body: hash_including(
            "channel" => "C1234567890",
            "text" => "Hello world",
            "post_at" => 1503435956,
            "blocks" => [{"type" => "section"}]
          )
        ).to_return(status: 200, body: {"ok" => true}.to_json)

        client.chat_schedule_message(
          channel: "C1234567890",
          text: "Hello world",
          post_at: 1503435956,
          blocks: [{"type" => "section"}]
        )
      end
    end
  end

  describe "#scheduled_messages_list" do
    before do
      stub_request(:post, "https://slack.com/api/scheduled_messages.list").to_return(response)
    end
    subject(:scheduled_messages_list) {
      client.scheduled_messages_list(channel: "C1234567890")
    }
    let(:response) {
      {
        status: 200,
        body: {"ok" => true, "scheduled_messages" => []}.to_json
      }
    }
    it "returns a successful response" do
      expect(scheduled_messages_list.ok?).to eq(true)
    end

    context "with optional parameters" do
      it "includes optional parameters when provided" do
        stub_request(:post, "https://slack.com/api/scheduled_messages.list").with(
          body: hash_including(
            "channel" => "C1234567890",
            "cursor" => "cursor_123",
            "latest" => "1503435956.000247",
            "limit" => 100,
            "oldest" => "1503435950.000247",
            "team_id" => "T123"
          )
        ).to_return(status: 200, body: {"ok" => true, "scheduled_messages" => []}.to_json)

        client.scheduled_messages_list(
          channel: "C1234567890",
          cursor: "cursor_123",
          latest: "1503435956.000247",
          limit: 100,
          oldest: "1503435950.000247",
          team_id: "T123"
        )
      end
    end
  end

  describe "#chat_delete_scheduled_message" do
    before do
      stub_request(:post, "https://slack.com/api/chat.deleteScheduledMessage").to_return(response)
    end
    subject(:chat_delete_scheduled_message) {
      client.chat_delete_scheduled_message(
        channel: "C1234567890",
        scheduled_message_id: "Q1234567890"
      )
    }
    let(:response) {
      {
        status: 200,
        body: {"ok" => true}.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_delete_scheduled_message.ok?).to eq(true)
    end
  end

  describe "#chat_get_permalink" do
    before do
      stub_request(:post, "https://slack.com/api/chat.getPermalink").to_return(response)
    end
    subject(:chat_get_permalink) {
      client.chat_get_permalink(
        channel: "C1234567890",
        message_ts: "1503435956.000247"
      )
    }
    let(:response) {
      {
        status: 200,
        body: {"ok" => true, "permalink" => "https://example.slack.com/archives/C1234567890/p1503435956000247"}.to_json
      }
    }
    it "returns a successful response" do
      expect(chat_get_permalink.ok?).to eq(true)
    end
  end
end
