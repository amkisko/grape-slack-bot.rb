module SlackBot
  class MenuOptions
    attr_reader :current_user, :params, :config
    def initialize(current_user:, params:, config: nil)
      @current_user = current_user
      @params = params
      @config = config || SlackBot::Config.current_instance
    end

    def call
      nil
    end
  end
end
