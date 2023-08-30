module SlackBot
  class Logger
    def info(*args, **kwargs)
      puts args.inspect if args.any?
      puts kwargs.inspect if kwargs.any?
    end
  end
end
