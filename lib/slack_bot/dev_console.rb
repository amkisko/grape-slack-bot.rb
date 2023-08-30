module SlackBot
  class DevConsole
    def self.enabled=(value)
      @enabled = value
    end

    def self.enabled?
      @enabled
    end

    def self.logger=(value)
      @logger = value
    end

    def self.logger
      @logger ||= Logger.new
    end

    def self.log(message = nil, &block)
      return unless enabled?

      message = yield if block_given?
      logger.info(message)
    end

    def self.log_input(message = nil, &block)
      message = yield if block_given?
      log(">>> #{message}")
    end

    def self.log_output(message = nil, &block)
      message = yield if block_given?
      log("<<< #{message}")
    end

    def self.log_check(message = nil, &block)
      message = yield if block_given?
      log("!!! #{message}")
    end
  end
end
