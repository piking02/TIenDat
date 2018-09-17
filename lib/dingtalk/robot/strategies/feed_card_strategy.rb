# frozen_string_literal: true

module Dingtalk
  class Robot
    # Markdown type strategy for sending message
    class FeedCardStrategy
      Link = Struct.new(:title, :messageURL, :picURL)

      def initialize(webhook_url, message)
        @webhook_url = webhook_url
        @message = message
      end

      # @option options [Array<Link>, Link] :links
      def notify(**options)
        links = Array.wrap(options[:links])
        all_present = links.all? { |link| link.all?(&:present?) }
        raise ArgumentError, 'All items of links must be present, strategy: feed_card' unless all_present
        body = generate_body(links)
        headers = {
          'Content-Type': 'application/json',
          Accept: 'application/json'
        }
        Net::HTTP.post(URI(webhook_url), body.to_json, headers).body
      end

      private

      attr_reader :webhook_url, :message

      def generate_body(links)
        {
          msgtype: 'feedCard',
          feedCard: {
            links: links
          }
        }
      end
    end
  end
end
