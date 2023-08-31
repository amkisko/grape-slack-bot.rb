require 'slack_bot/concerns/interaction_klass'
require 'slack_bot/concerns/view_klass'

module SlackBot
  class Command
    include SlackBot::Concerns::InteractionKlass
    include SlackBot::Concerns::ViewKlass

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

    def render_view(view_name, context: nil)
      view = self.class.view_klass.new(
        args: args,
        current_user: @current_user,
        params: params,
        context: context,
        config: config
      )
      view.send(view_name)
    end

    def open_modal(view_name, context: nil, callback: nil)
      callback ||= Callback.create(
        class_name: self.class.name,
        user: @current_user,
        channel_id: params[:channel_id],
        config: config
      )
      view_payload = render_view(view_name, context: context)
      self.class.interaction_klass.open_modal(
        callback: callback,
        trigger_id: params[:trigger_id],
        view: view_payload
      )
      render_response
    end
  end
end
