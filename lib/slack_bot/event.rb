require 'slack_bot/concerns/interaction_klass'
require 'slack_bot/concerns/view_klass'

module SlackBot
  class Event
    include SlackBot::Concerns::InteractionKlass
    include SlackBot::Concerns::ViewKlass

    attr_reader :current_user, :params, :config, :callback, :metadata
    def initialize(current_user: nil, params: nil, callback: nil, config: nil)
      @current_user = current_user
      @params = params
      @callback = callback
      @config = config || SlackBot::Config.current_instance
    end

    def call
      nil
    end

    private

    def callback=(callback)
      @callback = callback
    end

    def metadata=(metadata)
      @metadata = metadata
    end

    def event_type
      params["event"]["type"]
    end

    def render_view(view_name, context: nil)
      view = self.class.view_klass.new(
        args: callback&.args,
        current_user: current_user,
        params: params,
        context: context,
        config: config
      )
      view.send(view_name)
    end

    def publish_view(view_method_name, context: nil, metadata: nil)
      user_id = params["event"]["user"]
      view = render_view(view_method_name, context: context)

      SlackBot::Interaction.publish_view(
        callback: callback,
        metadata: metadata,
        user_id: user_id,
        view: view
      )

      nil
    end
  end
end
