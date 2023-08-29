module SlackBot
  class DevConsole
    def self.enabled=(value)
      @enabled = value
    end

    def self.enabled?
      @enabled
    end

    def self.log(message = nil, &)
      return unless enabled?

      message = yield if block_given?
      Rails.logger.info(message)
    end

    def self.log_input(message = nil, &)
      message = yield if block_given?
      log(">>> #{message}")
    end

    def self.log_output(message = nil, &)
      message = yield if block_given?
      log("<<< #{message}")
    end

    def self.log_check(message = nil, &)
      message = yield if block_given?
      log("!!! #{message}")
    end
  end
end
