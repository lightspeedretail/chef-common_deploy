module CommonDeploy
  # Library helper designed to help iterate over the application node
  # attributes in a consistent manner while applying default attributes.
  # @since 0.1.0
  module Applications
    class << self
      # Root attribute containing application hashes
      # @return [Hash] the application attributes
      # @since 0.2.0
      def root
        Chef.run_context.node['common_deploy']
      end

      # Default application attributes
      # @return [Hash]
      # @since 0.1.0
      def default
        root.fetch('default', {})
      end

      # Fetch a specific application by name
      # @param app_name [String] the application name to fetch from root
      # @param with_default [Bool] whether to merge on top of defaults
      # @return [Hash] the application attributes
      # @since 0.1.0
      def fetch(app_name, with_default: true)
        application_hash = root.fetch(app_name, {})
        default_hash = with_default ? default : {}
        Chef::Mixin::DeepMerge.merge(default_hash, application_hash)
      end

      # Fetch a specific application by name
      # @param app_name [String] the application name to fetch from root
      # @return [Hash] the appliation attributes
      # @since 0.2.0
      def [](app_name)
        fetch(app_name)
      end

      # List of all application names optionally in the order dictated by the
      # optional `order` key.
      # @return [Array] the application key names
      # @since 0.2.0
      def names
        root.keys
          .select { |k| k != 'default' }
          .sort_by { |k| fetch(k, with_default: false)['order'] || 50 }
      end

      # Hash of all of the applications, optionally with the default applied,
      # and optionally with the ordering applied as well. Ordering of the hash
      # is due to ruby preserving the order in which keys are added.
      # @return [Hash]
      # @since 0.2.0
      def all(with_default: true)
        Hash[names.map { |k| [k, fetch(k, with_default: with_default)] }]
      end

      # Iterate over the applications, yielding to a block.
      # I trust you've seen this before :P
      # @yield [String, Hash] the application name and application hash
      # @since 0.1.0
      def each(with_default: true)
        all(with_default: with_default).each { |k, v| yield(k, v) }
      end
    end
  end
end

CommonApps = CommonDeploy::Applications
