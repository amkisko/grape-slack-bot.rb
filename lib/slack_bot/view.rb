require 'active_support/core_ext/hash/indifferent_access'
require 'slack_bot/concerns/pager_klass'

module SlackBot
  class View
    include SlackBot::Concerns::PagerKlass

    attr_reader :args, :current_user, :params, :context, :config
    def initialize(current_user:, params:, args: nil, context: nil, config: nil)
      @current_user = current_user
      @params = params
      @config = config || SlackBot::Config.current_instance

      @args = args
      @context = context.with_indifferent_access if context.is_a?(Hash)
    end

    def method_missing(method_name, *args, &block)
      return @context[method_name.to_sym] if @context.key?(method_name.to_sym)

      super
    end

    def text_modal
      {
        title: {
          type: "plain_text",
          text: context[:title]
        },
        blocks: [
          { type: "section", text: { type: "mrkdwn", text: context[:text] } }
        ]
      }
    end

    private

    def divider_block
      { type: "divider" }
    end

    def current_date
      Date.current
    end

    def command
      params[:command]
    end

    def paginate(cursor)
      self.class.pager_klass.new(cursor, args: args)
    end
  end
end
