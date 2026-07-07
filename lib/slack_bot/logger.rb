module SlackBot
  class Logger
    class << self
      def info(...)
        logger_backend.info(...)
      end

      def error(...)
        logger_backend.error(...)
      end

      def warn(...)
        logger_backend.warn(...)
      end

      def debug(...)
        logger_backend.debug(...)
      end

      private

      def logger_backend
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger
        else
          @logger_backend ||= new
        end
      end
    end

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
