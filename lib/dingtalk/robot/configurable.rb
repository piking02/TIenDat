# frozen_string_literal: true

module Dingtalk
  class Robot
    VALID_MESSAGE_TYPES = Dir["#{__dir__}/strategies/*"].map { |path| File.basename(path, '_strategy.rb').to_sym }
    WEBHOOK_BASE_URL = 'https://oapi.dingtalk.com/robot/send?access_token='

    # @example Config single item
    #   Dingtalk::Robot.tokens = { default: 'TOKENXXXXXXXXXXX' }
    # @example Config multiple items
    #   Dingtalk::Robot.configure do |config|
    #     config.tokens       = { defautl: 'TOKENXXXXXXXXX' }
    #     config.message_type = :markdown
    #     config.template_dir = 'app/views/dingtalk/robot'
    #   end
    module Configurable
      def self.included(base)
        base.extend ClassMethods
      end

      # @see Configurable
      module ClassMethods
        def configure
          yield config
        end

        def config
          @config ||= Configuration.new
        end
      end

      # @see Configurable
      class Configuration
        attr_reader :message_type

        def initialize
          self.message_type = :text
        end

        def tokens=(tokens)
          @tokens = tokens.to_h.symbolize_keys!
        end

        def tokens
          @tokens.presence || (raise ConfigurationError.new(:tokens, @tokens, Hash))
        end

        def template_dir=(template_dir)
          @template_dir = template_dir.to_s
        end

        def template_dir
          @template_dir.presence || (raise ConfigurationError.new(:template_dir, @template_dir, String))
        end

        def message_type=(message_type)
          unless VALID_MESSAGE_TYPES.include?(message_type.to_sym)
            raise ConfigurationError.new(:message_type, message_type, VALID_MESSAGE_TYPES)
          end
          @message_type = message_type.to_sym
        end
      end
    end
  end
end
