require 'active_support/core_ext/hash/indifferent_access'

module SlackBot
  class View
    def self.pager_klass
      SlackBot::Pager
    end

    def self.pager(klass)
      define_singleton_method(:pager_klass) { klass }
    end

    attr_reader :args, :current_user, :params, :context, :config
    def initialize(current_user:, params:, args: nil, context: nil, config: nil)
      @current_user = current_user
      @params = params
      @config = config || SlackBot::Config.current_instance

      @args = args
      @context = context.with_indifferent_access if context.is_a?(Hash)
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

    def current_date
      Date.current
    end

    def divider_block
      { type: "divider" }
    end

    def command
      params[:command]
    end

    def paginate(cursor)
      SlackBot::Pager.new(cursor, args: args)
    end
  end
end
