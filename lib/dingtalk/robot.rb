# frozen_string_literal: true

require 'active_support/all'
require 'net/http'
require 'dingtalk/robot/configurable'
require 'dingtalk/robot/errors'
require 'dingtalk/robot/strategies/text_strategy'
require 'dingtalk/robot/strategies/markdown_strategy'

module Dingtalk
  # DingTalk Group Robot
  # @see https://open-doc.dingtalk.com/microapp/serverapi2/qf2nxq
  class Robot
    include Configurable
    delegate :notify, to: :message_strategy

    # @param channel      [#to_sym] Set both api token and message template
    # @param message_type [#to_sym] (:text) Message type
    # @example
    #   # Config api token and message template directory
    #   Dingtalk::Robot.config.tokens       = { order: 'WEBHOOK...' }
    #   Dingtalk::Robot.config.template_dir = '.'
    #   system %q(echo 'hello, <%= @name %>' > order.text.erb)
    #
    #   # Notify message
    #   robot = Dingtalk::Robot.new(:order) { @name = 'Pine Wong' }
    #   robot.notify
    def initialize(channel, message_type = nil, &context_block)
      @channel = channel.to_sym
      self.message_type = message_type&.to_sym
      @context_block = context_block
    end

    private

    attr_reader :channel, :message_type, :context_block
    delegate :config, to: :class

    # @param message_type [Symbol, nil]
    def message_type=(message_type)
      @message_type = message_type || begin
        template_paths = Dir["#{config.template_dir}/#{channel}.*.erb"]
        if template_paths.empty?
          raise ArgumentError, "Undefined channel template, channel: #{channel}, template_dir: #{config.template_dir}"
        end
        types = template_paths.map do |template_path|
          template_path[%r{#{config.template_dir}/#{channel}.([a-zA-Z]+).erb}, 1].to_sym
        end
        types.include?(config.message_type) ? config.message_type : types.first
      end
      valid = VALID_MESSAGE_TYPES.include?(@message_type)
      raise ConfigurationError.new(:message_type, @message_type, VALID_MESSAGE_TYPES) unless valid
    end

    def message_strategy
      self.class.const_get("#{message_type.to_s.camelize}Strategy").new(webhook_url, message)
    end

    def webhook_url
      token = config.tokens[channel]
      raise ArgumentError, "Undefined channel token, channel: #{channel}, tokens: #{config.tokens}" unless token
      "#{WEBHOOK_BASE_URL}#{token}"
    end

    def message
      path = "#{config.template_dir}/#{channel}.#{message_type}.erb"
      ERB.new(File.read(path)).result(context)
    rescue Errno::ENOENT
      raise ArgumentError, "Undefined channel template, channel: #{channel}, path: #{path}"
    end

    def context
      blank_object = Object.new
      blank_object.instance_eval(&context_block) if context_block
      blank_object.instance_eval { binding }
    end
  end
end
