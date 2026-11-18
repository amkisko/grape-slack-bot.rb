describe SlackBot::ApiClient do
  subject(:client) { described_class.new(authorization_token: "test_schema") }

  it "pushes a modal with the trigger and view" do
    view = {type: "modal"}
    request = stub_request(:post, "https://slack.com/api/views.push")
      .with(body: JSON.generate(trigger_id: "trigger", view: view), headers: {Authorization: "Bearer test_schema"})
      .to_return(status: 200, body: '{"ok":true}')

    expect(client.views_push(trigger_id: "trigger", view: view)).to be_ok
    expect(request).to have_been_requested
  end

  it "posts a response URL without forwarding the Web API token" do
    url = "https://hooks.slack.com/actions/test/fixture/path"
    request = stub_request(:post, url).with do |incoming|
      !incoming.headers.key?("Authorization") &&
        JSON.parse(incoming.body) == {"text" => "Saved", "response_type" => "in_channel"}
    end.to_return(status: 200, body: "ok")

    response = client.response_url_post(url, text: "Saved", response_type: "in_channel")

    expect(response).to be_ok
    expect(request).to have_been_requested
  end

  it "reports unavailable response URLs without exposing their credentials" do
    url = "https://hooks.slack-gov.com/actions/test/fixture/path"
    stub_request(:post, url).to_return(status: 410, body: "expired")

    expect(client.response_url_post(url, delete_original: true)).not_to be_ok
  end

  it "rejects destinations outside Slack before making a request" do
    expect {
      client.response_url_post("https://demo.7c3e9a1b/actions/test", text: "Saved")
    }.to raise_error(SlackBot::Errors::SlackApiError, "Invalid Slack response URL")
  end
end
