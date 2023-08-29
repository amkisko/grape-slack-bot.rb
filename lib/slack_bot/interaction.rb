module SlackBot
  class Interaction
    SlackViewsReply = Data.define(:callback_id, :view_id)

    def self.view(klass)
      define_singleton_method(:view_klass) { klass }
    end

    def self.open_modal(
      trigger_id:,
      payload:,
      class_name:,
      method_name:,
      user:,
      channel_id:,
      config: nil
    )
      callback =
        Callback.create(
          class_name: class_name,
          method_name: method_name,
          user: user,
          channel_id: channel_id,
          config: config
        )

      view = payload.merge({ type: "modal", callback_id: callback.id })
      response =
        SlackBot::ApiClient.new.views_open(trigger_id: trigger_id, view: view)

      if !response.ok?
        raise SlackBot::Errors::OpenModalError.new(response.error, data: response.data, payload: payload)
      end

      view_id = response.data.dig("view", "id")
      callback.update(view_id: view_id) if view_id.present?

      SlackViewsReply.new(callback.id, view_id)
    end

    def self.update_modal(
      callback_id: nil,
      view_id:,
      payload:,
      class_name: nil,
      method_name: nil,
      user: nil,
      channel_id: nil,
      config: nil
    )
      callback = Callback.find(callback_id, config: config) if callback_id.present?
      callback ||=
        Callback.create(
          class_name: class_name,
          method_name: method_name,
          user: user,
          channel_id: channel_id,
          config: config
        )

      view = payload.merge({ type: "modal", callback_id: callback.id })
      response =
        SlackBot::ApiClient.new.views_update(view_id: view_id, view: view)

      if !response.ok?
        raise SlackBot::Errors::UpdateModalError.new(response.error, data: response.data, payload: payload)
      end

      view_id = response.data.dig("view", "id")
      callback.update(view_id: view_id) if view_id.present?

      SlackViewsReply.new(callback.id, view_id)
    end

    attr_reader :current_user, :params, :callback, :config
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

    def interaction_type
      payload["type"]
    end

    def actions
      payload["actions"]
    end

    def update_modal(view_name, context: nil)
      return if callback.blank?

      view_id = payload["view"]["id"]
      args = callback.args
      view =
        self.class.view_klass.new(
          args: args,
          current_user: current_user,
          params: params,
          context: context,
          config: config
        )
      payload = view.send(view_name)

      self.class.update_modal(
        view_id: view_id,
        payload: payload,
        callback_id: callback.id,
        config: config
      )
    end

    def update_callback_args(&block)
      return if callback.blank?
      return if actions.blank?

      if block_given?
        actions.each { |action| instance_exec(action, &block) }
      else
        callback.args.raw_args = actions.first["value"]
      end

      callback.save
    end

    def payload
      @payload ||= JSON.parse(params[:payload])
    end
  end
end
