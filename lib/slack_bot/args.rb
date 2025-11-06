require "rack/utils"
require "active_support"
require "active_support/core_ext/hash/indifferent_access"

module SlackBot
  class ArgsParser
    def initialize(args)
      @args = args
    end

    def call
      Rack::Utils.parse_query(@args)
    end
  end

  class ArgsBuilder
    def initialize(args)
      @args = args
    end

    def call
      Rack::Utils.build_query(@args)
    end
  end

  class Args
    attr_accessor :args
    def initialize(builder: ArgsBuilder, parser: ArgsParser)
      @args = {}
      @builder = builder
      @parser = parser
    end

    def [](key)
      args[key]
    end

    def []=(key, value)
      args[key] = value
    end

    def raw_args=(raw_args)
      @raw_args = raw_args
      self.args = @parser.new(raw_args).call&.with_indifferent_access || {}
    end

    attr_reader :raw_args

    def to_s
      @builder.new(args).call
    end

    def merge(**other_args)
      self.class.new.tap do |new_args|
        new_args.args = args.merge(other_args)
      end
    end

    def except(*keys)
      self.class.new.tap do |new_args|
        new_args.args = args.except(*keys)
      end
    end
  end
end
