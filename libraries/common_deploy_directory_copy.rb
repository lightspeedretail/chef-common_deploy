require 'chef/resource/directory'
require 'chef/provider/directory'
require 'pathname'
require 'fileutils'

class Chef
  class Resource
    # Chef resource providing the functionality to copy the contents of
    # a directory into another (optionally new) directory. This resource will
    # not look at the contents of the files and will only create them if
    # missing. As such, it will _not_ detect if the source files have
    # been changed since being copied.
    #
    # @since 1.0.0
    class CommonDeployDirectoryCopy < Chef::Resource::Directory
      # Source property which defines the location of the directory to copy
      # @since 1.0.0
      def source(args = nil)
        set_or_return(:source, args, kind_of: String)
      end

      # Optional array of paths to exclude when copying
      # @note . and .. will always be added to this value
      # @since 1.0.0
      def exclude(args = nil)
        args = Array(args) if args
        set_or_return(:exclude, args, kind_of: Array, default: [])
      end
    end
  end
end

class Chef
  class Provider
    # Chef provider
    #
    # @since 1.0.0
    class CommonDeployDirectoryCopy < Chef::Provider::Directory
      provides :common_deploy_directory_copy

      # Glob match of all items relative to the source directory
      # @return [Array] relative paths
      # @since 1.0.0
      def paths_in_source
        source = new_resource.source
        source_pathname = Pathname.new(source)

        ::Dir.glob(
          ::File.join(Chef::Util::PathHelper.escape_glob(source), '*'),
          ::File::FNM_DOTMATCH
        )
        .map do |item|
          Pathname.new(item).relative_path_from(source_pathname).to_s
        end
      end

      # Paths to exclude from `paths_in_source`
      # @return [Array]
      # @since 1.0.0
      def paths_excluded
        new_resource.exclude.concat(['.', '..']).uniq
      end

      # Relative paths within source with exclusions removed
      # @return [Array]
      # @since 1.0.0
      def files_to_transfer
        (paths_in_source - paths_excluded).sort_by do |relative_path|
          relative_path.count(::File::SEPARATOR)
        end
      end

      # Overload the Directory `create` action so as to ensure that the
      # content of the source directory is copied into the destination.
      # @since 1.0.0
      def action_create
        super

        missing_files_to_transfer = files_to_transfer.select do |relative|
          dst_path = ::File.join(new_resource.path, relative)
          !::File.exist?(dst_path)
        end

        unless missing_files_to_transfer.empty?
          converge_by("transfer files from #{@new_resource.source}") do
            missing_files_to_transfer.each do |relative_path|
              src_path = ::File.join(new_resource.source, relative_path)
              dst_path = ::File.join(new_resource.path, relative_path)

              FileUtils.cp_r(src_path, dst_path, preserve: true)
            end
          end
        end
      end
    end
  end
end
