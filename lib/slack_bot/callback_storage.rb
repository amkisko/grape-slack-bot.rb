module SlackBot
  class CallbackStorage
    def read(*_args, **_kwargs)
      raise SlackBot::Errors::NotImplementedError.new("CallbackStorage#read must be implemented by subclass")
    end

    def write(*_args, **_kwargs)
      raise SlackBot::Errors::NotImplementedError.new("CallbackStorage#write must be implemented by subclass")
    end

    def delete(*_args, **_kwargs)
      raise SlackBot::Errors::NotImplementedError.new("CallbackStorage#delete must be implemented by subclass")
    end
  end
end
