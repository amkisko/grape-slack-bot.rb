# 1.5.7

* Raise error if handler class not resolved
* App home interaction example added
* Callback logic and usage fixed
* Views improvements

# 1.5.0

* Complete upgrade of callback storage logic

# 1.4.0

* Allow setting callback expiration time on save and update

# 1.3.0

* Clean up callback arguments, remove unused `method_name`

# 1.2.3

* Minor fix for Events API

# 1.2.2

* `SlackBot::Callback.find` method will raise `SlackBot::Errors::CallbackNotFound` if callback is not resolved or has wrong data

# 1.2.1

* Extract `SlackBot::Logger` to separate file

# 1.2.0

* Remove `Rails.logger` dependency, make logger configurable

# 1.1.0

* Set minimum ruby version requirement to 2.5.0

# 1.0.5

* Add superclass `SlackBot::Error` for all errors

# 1.0.2

* Soften dependencies version requirements

# 1.0.1

* Bump Faraday version to 2.7.10

# 1.0.0

* Initial version
