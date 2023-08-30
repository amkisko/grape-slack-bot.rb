module SlackBot
  class Event
    def self.view(klass)
      define_singleton_method(:view_klass) { klass }
    end

    attr_reader :current_user, :params, :config
    attr_accessor :callback, :metadata
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

    def event_type
      params["event"]["type"]
    end

    def publish_view(view_method_name, context: nil)
      user_id = params["event"]["user"]
      view =
        self.class.view_klass
          .new(current_user: current_user, params: params, context: context)
          .send(view_method_name)
      view = view.merge(callback_id: callback.id) if callback.present?
      view = view.merge(private_metadata: metadata) if metadata.present?
      response =
        SlackBot::ApiClient.new.views_publish(user_id: user_id, view: view)

      if !response.ok?
        raise SlackBot::Errors::PublishViewError.new(response.error, data: response.data, payload: view)
      end

      nil
    end
  end
end
