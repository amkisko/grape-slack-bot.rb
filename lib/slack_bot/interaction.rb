require "active_support"
require "active_support/core_ext/object"

require "slack_bot/concerns/view_klass"

module SlackBot
  class Interaction
    SlackViewsReply = Struct.new(:callback_id, :view_id)

    include SlackBot::Concerns::ViewKlass

    def self.api_client
      @api_client ||= SlackBot::ApiClient.new
    end

    def self.api_client=(client)
      @api_client = client
    end

    def self.open_modal(callback:, trigger_id:, view:)
      view = modal_payload(callback, view)
      response = api_client.views_open(trigger_id: trigger_id, view: view)
      build_view_reply(response: response, callback: callback, payload: view, error_class: SlackBot::Errors::OpenModalError)
    end

    def self.update_modal(callback:, view_id:, view:)
      view = modal_payload(callback, view)
      response = api_client.views_update(view_id: view_id, view: view)
      build_view_reply(response: response, callback: callback, payload: view, error_class: SlackBot::Errors::UpdateModalError)
    end

    def self.publish_view(user_id:, view:, callback: nil, metadata: nil)
      response = api_client.views_publish(user_id: user_id, view: publish_payload(callback, metadata, view))
      build_view_reply(response: response, callback: callback, payload: view, error_class: SlackBot::Errors::PublishViewError)
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

    def self.modal_payload(callback, view)
      view.merge(type: "modal", callback_id: callback&.id)
    end

    def self.publish_payload(callback, metadata, view)
      view = view.merge(callback_id: callback.id) if callback.present?
      view = view.merge(private_metadata: metadata) if metadata.present?
      view
    end

    def self.build_view_reply(response:, callback:, payload:, error_class:)
      raise error_class.new(response.error, data: response.data, payload: payload) unless response.ok?

      view_id = response.data.dig("view", "id")
      persist_view_id(callback, view_id)
      SlackViewsReply.new(callback&.id, view_id)
    end

    def self.persist_view_id(callback, view_id)
      return unless callback.present? && view_id.present?

      callback.view_id = view_id
      callback.save
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
