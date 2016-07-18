module CommonDeploy
  # Library helper designed to fetch node attributes describing our
  # applications for easier template generation.
  # @since 0.1.0
  module Configs
    class << self
      # Fetch a specific application by name
      # @param app_name [String] the application name to fetch
      # @return [Hash] the application configuration hash
      # @since 0.1.0
      def fetch(app_name)
        CommonDeploy::Applications.fetch(app_name).fetch(:configuration, {})
      end

      # List of all application configuration blocks
      # @return [Array]
      # @since 0.1.0
      def all
        CommonDeploy::Applications.all
          .select { |_, v| v.fetch(:configuration, nil) }
          .map { |k, v| [k, v.fetch(:configuration)] }
      end
    end
  end
end
