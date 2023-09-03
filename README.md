# grape-slack-bot.rb

[![Gem Version](https://badge.fury.io/rb/grape-slack-bot.svg)](https://badge.fury.io/rb/grape-slack-bot) [![Test Status](https://github.com/amkisko/grape-slack-bot.rb/actions/workflows/test.yml/badge.svg)](https://github.com/amkisko/grape-slack-bot.rb/actions/workflows/test.yml) [![codecov](https://codecov.io/gh/amkisko/grape-slack-bot.rb/graph/badge.svg?token=VIZ94XFOR3)](https://codecov.io/gh/amkisko/grape-slack-bot.rb)

Extensible Slack bot implementation gem for [ruby-grape](https://github.com/ruby-grape/grape)

Sponsored by [Kisko Labs](https://www.kiskolabs.com).

## Install

Using Bundler:
```sh
bundle add grape-slack-bot
```

Using RubyGems:
```sh
gem install grape-slack-bot
```

## Gemfile

```ruby
gem 'grape-slack-bot'
```

## Gem modules and classes

`SlackBot` is the main module that contains all the classes and modules.

## Concepts

### Slash command

Slash command is a command that is triggered by user in Slack chat using `/` prefix.

Characteristics:
- Can have multiple URL endpoints (later called `url_token`, e.g. `/api/slack/commands/game`)
- Starts with `/` and is followed by command name (e.g. `/game`, called `token`)
- Can have multiple argument commands (e.g. `/game start`, called `token`)
- Can have multiple arguments (e.g. `/game start password=P@5sW0Rd`, called `args`)
- Can send message to chat
- Can open interactive component with callback identifier
- Can trigger event in background

References:
- [slash_command.rb](lib/slack_bot/slash_command.rb)
- [Slash command documentation](https://api.slack.com/interactivity/slash-commands)

### Interactive component

Interactive component is a component that is requested to be opened by bot app for the user in Slack application.

Characteristics:
- Can be associated with slash command
- Can be associated with event

References:
- [interaction.rb](lib/slack_bot/interaction.rb)
- [Interactive components documentation](https://api.slack.com/interactivity/handling)

### Event

Event is a notification that is sent to bot app when something happens in Slack.

References:
- [event.rb](lib/slack_bot/event.rb)
- [Event documentation](https://api.slack.com/events-api)

### View

View is a class that has logic for rendering internals of message or modal or any other user interface component.

Characteristics:
- Can be associated with slash command, interactive component or event for using ready-made methods like `open_modal`, `update_modal` or `publish_view`

References:
- [view.rb](lib/slack_bot/view.rb)
- [App home documentation](https://api.slack.com/surfaces/app-home)
- [Messages documentation](https://api.slack.com/messaging)
- [Modals documentation](https://api.slack.com/surfaces/modals)

### Block

Block is an object that is used to render user interface elements in Slack.

References:
- [Block kit documentation](https://api.slack.com/block-kit)

### Callback

Callback is a class for managing interactive component state and handling interactive component actions.

Example uses `Rails.cache` for storing interactive component state, use `CallbackStorage` for building custom storage class as a base.

References:
- [callback.rb](lib/slack_bot/callback.rb)
- [callback_storage.rb](lib/slack_bot/callback_storage.rb)

### Arguments

Class for handling slash command and interactive element values as queries.

Gem implementation uses `Rack::Utils` for parsing and building query strings.

References:
- [args.rb](lib/slack_bot/args.rb)

### Pager

Own implementation of pagination that is relying on [Arguments](#arguments) and [ActiveRecord](https://guides.rubyonrails.org/active_record_querying.html).

References:
- [pager.rb](lib/slack_bot/pager.rb)

## Specification

- [x] Create any amount of endpoints that will handle Slack calls
- [x] Create multiple instances of bots and configure them separately or use the same configuration for all bots
- [x] Define and reuse slash command handlers for Slack slash commands
- [x] Define interactive component handlers for Slack interactive components
- [x] Define and reuse views for slash commands, interactive components and events
- [x] Define event handlers for Slack events
- [x] Define menu options handlers for Slack menu options
- [x] Store interactive component state in cache for usage in other handlers
- [x] Access current user session and user from any handler
- [x] Extend API endpoint with custom hooks and helpers within [grape specification](https://github.com/ruby-grape/grape)
- [x] Supports Slack signature verification
- [ ] Supports Slack socket mode (?)
- [ ] Supports Slack token rotation

## Usage with grape

Create `app/api/slack_bot_api.rb`, it will contain bot configuration and endpoints setup:

```ruby
SlackBot::DevConsole.logger = Rails.logger
SlackBot::DevConsole.enabled = Rails.env.development?
SlackBot::Config.configure do
  callback_storage Rails.cache
  callback_user_finder ->(id) { User.active.find_by(id: id) }

  # TODO: Register event handlers
  event :app_home_opened, MySlackBot::AppHomeOpenedEvent
  interaction MySlackBot::AppHomeInteraction

  # TODO: Register slash command handlers
  slash_command_endpoint :game, MySlackBot::Game::MenuCommand do
    command :start, MySlackBot::Game::StartCommand
  end
end

class SlackBotApi < Grape::API
  include SlackBot::GrapeExtension

  helpers do
    def config
      SlackBot::Config.current_instance
    end

    def resolve_user_session(team_id, user_id)
      uid = OmniAuth::Strategies::SlackOpenid.generate_uid(team_id, user_id)
      UserSession.find_by(uid: uid, provider: UserSession.slack_openid_provider)
    end

    def current_user_session
      # NOTE: fetch_team_id and fetch_user_id are provided by SlackBot::Grape::ApiExtension
      @current_user_session ||=
        resolve_user_session(fetch_team_id, fetch_user_id)
    end

    def current_user_ip
      request.env["action_dispatch.remote_ip"].to_s
    end

    def current_user
      @current_user ||= current_user_session&.user
    end
  end
end
```

In routes file `config/routes.rb` mount the API:

```ruby
mount SlackBotApi => "/api/slack"
```

## Slack bot manifest

You can use this manifest as a template for your Slack app configuration:

```yaml
display_information:
  name: Example
  description: Example bot
  background_color: "#000000"
features:
  bot_user:
    display_name: Example
    always_online: true
  slash_commands:
    - command: /game
      url: https://example.com/api/slack/commands/game
      description: The game
      should_escape: false
oauth_config:
  redirect_urls:
    - https://example.com/user/auth/slack_openid/callback
  scopes:
    bot:
      - incoming-webhook
      - app_mentions:read
      - chat:write
      - users:read
      - users:read.email
      - im:read
      - im:write
      - im:history
      - channels:read
      - groups:read
      - mpim:read
      - reactions:read
      - commands
settings:
  event_subscriptions:
    request_url: https://example.com/api/slack/events
    bot_events:
      - app_home_opened
      - app_mention
      - im_history_changed
      - member_joined_channel
      - member_left_channel
      - message.im
      - profile_opened
      - reaction_added
      - reaction_removed
  interactivity:
    is_enabled: true
    request_url: https://example.com/api/slack/interactions
    message_menu_options_url: https://example.com/api/slack/menu_options
  org_deploy_enabled: false
  socket_mode_enabled: false
  token_rotation_enabled: false
```

## Command example

```ruby
module MySlackBot::Game
  class MenuCommand < SlackBot::Command
    interaction MySlackBot::Game::MenuInteraction
    view MySlackBot::Game::MenuView
    def call
      open_modal :index_modal
    end
  end
  class StartCommand < SlackBot::Command
    interaction MySlackBot::Game::StartInteraction
    view MySlackBot::Game::StartView
    def call
      open_modal :index_modal
    end
  end
end

```

## Interaction example

```ruby
module MySlackBot::Game
  class StartInteraction < SlackBot::Interaction
    view MySlackBot::Game::StartView
    def call
      return if interaction_type != "block_actions"

      update_callback_args do |action|
        action_id = action["action_id"]
        action_type = action["type"]
        case action_type
        when "static_select"
          if action_id == "games_users_list_select_user"
            callback.args[:user_id] = action["selected_option"]["value"]
          end
        else
          callback.args.raw_args = action["value"]
        end
      end

      update_modal :index_modal
    end
  end
end
```

App home interaction example:

```ruby
module MySlackBot
  class AppHomeInteraction < SlackBot::Event
    view MySlackBot::AppHomeView

    def call
      action_id = payload.dig("actions", 0, "action_id")
      case action_id
      when "add_game"
        add_game
      end
    end

    private

    def add_game
      open_modal :add_game_modal
    end
  end
end
```

## View example

Modal view example:

```ruby
module MySlackBot::Game
  class MenuView < SlackBot::View
    def index_modal
      blocks = []

      blocks << {
        type: "section",
        block_id: "section_help_list",
        text: {
          type: "mrkdwn",
          text: "#{command} start - Start the game"
        }
      }

      cursor = Game.active
      pager = paginate(cursor)

      blocks << {
        type: "section",
        block_id: "section_games_list",
        text: {
          type: "mrkdwn",
          text: "*Games*"
        }
      }

      if pager.cursor.present?
        pager.cursor.find_each do |game|
          blocks << {
            type: "section",
            block_id: "section_game_#{game.id}",
            text: {
              type: "mrkdwn",
              text: "#{game.name}"
            },
            accessory: {
              type: "button",
              action_id: "games_users_list_join_game",
              text: {
                type: "plain_text",
                text: "Join"
              },
              value: args.merge(game_id: game.id).to_s
            }
          }
        end
      else
        blocks << {
          type: "section",
          block_id: "section_games_list_empty",
          text: {
            type: "mrkdwn",
            text: "No active games"
          }
        }
      end

      if pager.pages_count > 1
        pager_elements = []
        if pager.page > 1
          pager_elements << {
            type: "button",
            action_id: "games_list_previous_page",
            text: {
              type: "plain_text",
              text: ":arrow_left: Previous page"
            },
            value: args.merge(page: pager.page - 1).to_s
          }
        end
        if pager.page < pager.pages_count
          pager_elements << {
            type: "button",
            action_id: "games_list_next_page",
            text: {
              type: "plain_text",
              text: "Next page :arrow_right:"
            },
            value: args.merge(page: pager.page + 1).to_s
          }
        end
        if pager_elements.present?
          blocks << {
            type: "actions",
            elements: pager_elements
          }
        end
      end

      {
        title: {
          type: "plain_text",
          text: "Example help"
        },
        blocks: blocks
      }
    end
  end
end
```

App home view example:

```ruby
module MySlackBot
  class AppHomeView < SlackBot::View
    def index_view
      blocks = []
      if current_user.present?
        blocks += {
          type: "section",
          text: {
            type: "mrkdwn",
            text:
              "*Hello, #{current_user.name}!*"
          }
        }
      else
        blocks << {
          type: "section",
          text: {
            type: "mrkdwn",
            text:
              "*Please login at https://example.com using Slack*"
          }
        }
      end
      blocks << {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "Last updated at #{Time.current.strftime("%H:%M:%S %d.%m.%Y")}"
          }
        ]
      }
      { type: "home", blocks: blocks }
    end

    private

    def format_date(date)
      date.strftime("%d.%m.%Y")
    end
  end
end
```

## Event example

```ruby
module MySlackBot
  class AppHomeOpenedEvent < SlackBot::Event
    view MySlackBot::AppHomeView
    def call
      # NOTE: we have to create callback here in order to handle interactions
      self.callback = SlackBot::Callback.find_or_create(
        id: "app_home_opened",
        user: current_user,
        class_name: self.class.name
      )

      publish_view :index_view
    end
  end
end
```

## Extensibility

You can patch any class or module in this gem to extend its functionality, most of parts are not hardly attached to each other.

## Development and testing

For development and testing purposes you can use [Cloudflare Argo Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps) to expose your local development environment to the internet.

```sh
brew install cloudflare/cloudflare/cloudflared
cloudflared login
sudo cloudflared tunnel run --token <LONG_TOKEN_FROM_TUNNEL_PAGE>
```

For easiness of getting information, most of endpoints have `SlackBot::DevConsole.log` calls that will print out information to the console.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/amkisko/grape-slack-bot.rb

Contribution policy:
- It might take up to 2 calendar weeks to review and merge critical fixes
- It might take up to 6 calendar months to review and merge pull request
- It might take up to 1 calendar year to review an issue
- New Slack features are not nessessarily added to the gem
- Pull request should have test coverage for affected parts
- Pull request should have changelog entry

## Publishing

Prefer using script `usr/bin/release.sh`, it will ensure that repository is synced and after publishing gem will create a tag.

```sh
rm grape-slack-bot-*.gem
gem build grape-slack-bot.gemspec
gem push grape-slack-bot-*.gem
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
