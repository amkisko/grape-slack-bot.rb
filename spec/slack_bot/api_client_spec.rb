require "spec_helper"

describe SlackBot::ApiClient do
  subject(:client) { described_class.new(authorization_token: authorization_token) }
  let(:authorization_token) { "test_authorization_token" }

  it "does not raise errors" do
    expect { client }.not_to raise_error
  end

  context "when the authorization token is not set" do
    let(:authorization_token) { nil }
    it "raises an error" do
      expect { client }.to raise_error("Slack bot API token is not set")
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
    # TODO: Add a test for the response
  end
end
