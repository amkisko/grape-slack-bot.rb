module SlackBot
  class Logger
    def info(*args, **kwargs)
      puts args.inspect if args.any?
      puts kwargs.inspect if kwargs.any?
    end

    def error(*args, **kwargs)
      puts args.inspect if args.any?
      puts kwargs.inspect if kwargs.any?
    end

    def warn(*args, **kwargs)
      puts args.inspect if args.any?
      puts kwargs.inspect if kwargs.any?
    end

    def debug(*args, **kwargs)
      puts args.inspect if args.any?
      puts kwargs.inspect if kwargs.any?
    end
  end
end
