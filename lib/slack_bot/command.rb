module SlackBot
  class Command
    def self.interaction(klass)
      define_singleton_method(:interaction_klass) { klass }
    end

    def self.view(klass)
      define_singleton_method(:view_klass) { klass }
    end

    attr_reader :current_user, :params, :args, :config
    def initialize(current_user:, params:, args:, config: nil)
      @current_user = current_user
      @params = params
      @config = config || SlackBot::Config.current_instance

      @args = SlackBot::Args.new
      @args.raw_args = args
    end

    def command
      params[:command]
    end

    def text
      params[:text]
    end

    def only_user?
      true
    end

    def only_direct_message?
      true
    end

    def only_slack_team?
      true
    end

    def render_response(response_type = nil, **kwargs)
      return if !response_type

      {
        response_type: response_type
      }.merge(kwargs)
    end

    private

    def open_modal(view_name, method_name: nil, context: nil)
      view = self.class.view_klass.new(
        args: args,
        current_user: @current_user,
        params: params,
        context: context,
        config: config
      )
      payload = view.send(view_name)
      self.class.interaction_klass.open_modal(
        trigger_id: params[:trigger_id],
        channel_id: params[:channel_id],
        class_name: self.class.name,
        method_name: method_name,
        user: @current_user,
        payload: payload,
        config: config
      )
      render_response
    end
  end
end
