require "active_support"
require "active_support/core_ext/object"

require "slack_bot/concerns/view_klass"

module SlackBot
  class Interaction
    SlackViewsReply = Struct.new(:callback_id, :view_id)

    include SlackBot::Concerns::ViewKlass

    def self.open_modal(callback:, trigger_id:, view:)
      view = view.merge({type: "modal", callback_id: callback&.id})
      response =
        SlackBot::ApiClient.new.views_open(trigger_id: trigger_id, view: view)

      if !response.ok?
        raise SlackBot::Errors::OpenModalError.new(response.error, data: response.data, payload: view)
      end

      view_id = response.data.dig("view", "id")
      if callback.present? && view_id.present?
        callback.view_id = view_id
        callback.save
      end
      SlackViewsReply.new(callback&.id, view_id)
    end

    def self.update_modal(callback:, view_id:, view:)
      view = view.merge({type: "modal", callback_id: callback&.id})
      response =
        SlackBot::ApiClient.new.views_update(view_id: view_id, view: view)

      if !response.ok?
        raise SlackBot::Errors::UpdateModalError.new(response.error, data: response.data, payload: view)
      end

      view_id = response.data.dig("view", "id")
      if callback.present? && view_id.present?
        callback.view_id = view_id
        callback.save
      end
      SlackViewsReply.new(callback&.id, view_id)
    end

    def self.publish_view(user_id:, view:, callback: nil, metadata: nil)
      view = view.merge(callback_id: callback.id) if callback.present?
      view = view.merge(private_metadata: metadata) if metadata.present?
      response =
        SlackBot::ApiClient.new.views_publish(user_id: user_id, view: view)

      if !response.ok?
        raise SlackBot::Errors::PublishViewError.new(response.error, data: response.data, payload: view)
      end

      view_id = response.data.dig("view", "id")
      if callback.present? && view_id.present?
        callback.view_id = view_id
        callback.save
      end
      SlackViewsReply.new(callback&.id, view_id)
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

    def open_modal(view_name, context: nil)
      self.callback ||= Callback.create(
        class_name: self.class.name,
        user: @current_user,
        config: config
      )
      view_payload = render_view(view_name, context: context)
      self.class.open_modal(
        callback: callback,
        trigger_id: payload["trigger_id"],
        view: view_payload
      )
    end

    def update_modal(view_name, context: nil)
      return if callback.blank?

      view_id = payload["view"]["id"]
      payload = render_view(view_name, context: context)

      self.class.update_modal(
        view_id: view_id,
        view: payload,
        callback: callback
      )
    end

    def publish_view(view_method_name, context: nil, metadata: nil)
      user_id = payload["user"]["id"]
      view = render_view(view_method_name, context: context)

      SlackBot::Interaction.publish_view(
        callback: callback,
        metadata: metadata,
        user_id: user_id,
        view: view
      )

      nil
    end

    def update_callback_args(&block)
      return if callback.blank?
      return if actions.blank?

      if block
        actions.each { |action| instance_exec(action, &block) }
      else
        callback.args.raw_args = actions.first["value"]
      end

      callback.save
    end

    def payload
      @payload ||= begin
        JSON.parse(params[:payload])
      rescue JSON::ParserError => e
        raise SlackBot::Errors::InvalidPayloadError.new("Invalid JSON payload: #{e.message}")
      end
    end
  end
end
