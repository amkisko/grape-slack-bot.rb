# CHANGELOG

## Unreleased

- Fix status code handling for empty/false responses - ensure 200 OK instead of 204 No Content
- Fix closure variable scoping issues in helper methods using `define_method` for proper variable capture
- Fix missing `interaction_klass` method handling in `handle_block_actions_view` using `respond_to?` check
- Fix `resolve_user_session` method availability in test contexts
- Improve error handling for handler classes without `interaction_klass` method
- Add timestamp validation to signature verification to prevent replay attacks (security improvement)
- Add comprehensive error handling for JSON parsing failures
- Add network error handling for all Slack API client methods (Faraday exceptions)
- Add custom error classes: `CallbackUserMismatchError`, `InvalidPayloadError`, `SlackApiError`, `UnknownActionTypeError`
- Replace all generic `raise` statements with custom error classes
- Add error handling for unknown event types in events endpoint
- Simplify `verify_current_user!` method for better readability
- Improve error messages and error handling throughout the codebase
- Add RBS type signatures for better type checking and IDE support
- Add StandardRB configuration for consistent code style
- Update gemspec to include RBS signature files

## 1.8.2

- Update Slack API client to have more chat methods

## 1.8.1

- Clean up dependencies

## 1.8.0

- Rewind incoming request body when reading it

## 1.7.2

- Fix request secret headers parsing

## 1.7.0

- Add `usersList` and `chat.postEphemeral` methods
- Core upgrades and clean up

## 1.6.3

- Implement callback for modals

## 1.6.2

- Allow custom handler names for associating with interactions

## 1.6.1

- Unify command, event and interaction rendering methods

## 1.6.0

- Better visibility for missing handlers

## 1.5.8

- Fix event registration
- Update event interaction example

## 1.5.7

- Raise error if handler class not resolved
- App home interaction example added
- Callback logic and usage fixed
- Views improvements

## 1.5.0

- Complete upgrade of callback storage logic

## 1.4.0

- Allow setting callback expiration time on save and update

## 1.3.0

- Clean up callback arguments, remove unused `method_name`

## 1.2.3

- Minor fix for Events API

## 1.2.2

- `SlackBot::Callback.find` method will raise `SlackBot::Errors::CallbackNotFound` if callback is not resolved or has wrong data

## 1.2.1

- Extract `SlackBot::Logger` to separate file

## 1.2.0

- Remove `Rails.logger` dependency, make logger configurable

## 1.1.0

- Set minimum ruby version requirement to 2.5.0

## 1.0.5

- Add superclass `SlackBot::Error` for all errors

## 1.0.2

- Soften dependencies version requirements

## 1.0.1

- Bump Faraday version to 2.7.10

## 1.0.0

- Initial version
