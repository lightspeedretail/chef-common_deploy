
module CommonDeploy
  # Library helper designed to help iterate over the application node
  # attributes in a consistent manner while applying default attributes.
  # @since 0.1.0
  module Applications
    class << self
      # Source of the attributes
      # @return [Hash] the node attributes
      # @since 0.1.0
      def source
        Chef.run_context.node[:common_deploy]
      end

      # Default application attributes
      # @return [Hash]
      # @since 0.1.0
      def default
        source.fetch(:default, {})
      end

      # Fetch a specific application by name
      # @param app_name [String] the application name to fetch from source
      # @return [Hash] the application hash merged on top of the default hash
      # @since 0.1.0
      def fetch(app_name)
        application_hash = source.fetch(app_name, {})
        default_hash = default.select { |k, _| application_hash.key?(k) }

        Chef::Mixin::DeepMerge.merge(default_hash, application_hash)
      end

      # List of all the applications with the default applied and in the order
      # dictated by the option `order` key which defaults to 100.
      # @return [Array]
      # @since 0.1.0
      def all
        source.keys
          .select { |k| k != :default }
          .map { |k| [k, fetch(k)] }
          .sort_by { |_, h| h[:order] || 100 }
      end

      # Iterate over the applications, yielding to a block.
      # I trust you've seen this before :P
      # @yield [String,Hash] the AppName and AppHash
      # @since 0.1.0
      def each
        all.each { |k, h| yield(k, h) }
      end
    end
  end
end
