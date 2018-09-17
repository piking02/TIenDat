# frozen_string_literal: true

module Dingtalk
  class Robot
    # Markdown type strategy for sending message
    class ActionCardStrategy
      def initialize(webhook_url, message)
        @webhook_url = webhook_url
        @message = message
      end

      # @option options [String]  :title
      # @option options [String]  :single_title
      # @option options [String]  :single_url
      # @option options [Integer] :hide_avatar  (0) 0-show, 1-hide
      def notify(**options)
        title = options[:title].to_s
        raise ArgumentError, 'title must be present, strategy: action_card' if title.empty?
        single_title = options[:single_title].to_s
        raise ArgumentError, 'single_title must be present, strategy: action_card' if single_title.empty?
        single_url = options[:single_url].to_s
        raise ArgumentError, 'single_url must be present, strategy: action_card' if single_url.empty?
        hide_avatar = options[:hide_avatar].to_i
        body = generate_body(title, single_title, single_url, hide_avatar)
        headers = {
          'Content-Type': 'application/json',
          Accept: 'application/json'
        }
        Net::HTTP.post(URI(webhook_url), body.to_json, headers).body
      end

      private

      attr_reader :webhook_url, :message

      def generate_body(title, single_title, single_url, hide_avatar)
        {
          msgtype: 'actionCard',
          actionCard: {
            title: title,
            text: message,
            singleTitle: single_title,
            singleURL: single_url,
            hideAvatar: hide_avatar
          }
        }
      end
    end
  end
end
