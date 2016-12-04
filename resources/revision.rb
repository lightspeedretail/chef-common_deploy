# The common_deploy_revision resource functions similarly Chef's deploy_revision
# resource in that it enables you to deploy applications in an atomic manner
# in much the same way that Capistrano functions.
#
# The main difference lies in the fact that this resource provides for more
# execution hooks granting a better control over how and when steps are
# executed.
#
# The full sequence of events is as follows:
#
### Load current resource
# - detect whether this resource has changed
#   - is there a newer release hash on upstream?
#   - is there a the release published?
### Cache phase
# - if support_force
#   - delete the existing release folder
# - if release_hash has changed
#   - update the cache (utilizing scm_resource)
#   - copy the cache to the new release folder
#   - create the REVISION file in the release folder
#   * execute the after_cache callback
### Build phase
# * execute the before_build callback
# - if purge_on_build has changed
#   - delete directories recursively from the release folder
# - if create_on_build has changed
#   - create directories recursively in the release folder
# - if symlink_on_build has changed
#   - symlink release paths to shared paths
# * execute the after_build callback
# - if release_hash has changed
#   * execute the after_updated callback
### Migration phase
# - * execute the validate_migrate callback
# - if release_hash or current_path have changed and supports_migrate
#   * execute the before_migration callback
#   * execute the migrate_action callbackk
#   * execute the after_migration callback
### Publish phase
# - * execute the validate_publish callback
# - if release_hash or current_path have changed and supports_publish
#   * execute the before_publish callback
#   * create the current symlink
#   * log the publishing of this release
#   * execute the after_publish callback
#
# @example
# ```ruby
# common_deploy_revision '/var/www/myapp' do
#    user 'www-data'
#    group 'www-data'
#    revision 'master'
#    repository 'git@github.com:MyOrg/MyApp.git'
#    revision 'master'
#    scm_options "ssh_wrapper" => "/var/www/.ssh/deploy.cmd"
#
#    support_migrate true
#    support_publish true
#
#    validate_migrate do
#      supports!("migrate", false) if `conditional`
#    end
#
#    after_cache do
#      php_composer_command release_path do
#        arguments << 'install'
#        user new_resource.user
#        group new_resource.group
#      end
#    end
#
#    before_build do
#      directory shared_name("config") do
#        path  shared_path("config")
#        owner new_resource.user
#        group new_resource.group
#        mode  00755
#        recursive true
#      end
#    end
#
#    after_build do
#      release_template "config/secrets.yml" do
#        variables node['common_deploy']['configuration']['myapp']
#        notifies :run, "execute[backend/secrets.yml publish]", :immediately
#      end
#
#     run "public secrets.yml" do
#       command "bin/secrets"
#       action :nothing
#     end
#   end
# end
# ```
#
resource_name :common_deploy_revision

# Root path containing current symlink, releases and shared directory
# @since 0.1.0
property :deploy_to,
  kind_of: String,
  name_property: true,
  identity: true

# Owning user
# @since 0.1.0
property :user,
  kind_of: String

# Owning group
# @since 0.1.0
property :group,
  kind_of: String

# Repository from which to cache the source
# @since 0.1.0
property :repository,
  kind_of: String,
  required: true

# Revision to fetch from the source
# @since 0.1.0
property :revision,
  kind_of: String,
  identity: true,
  default: 'HEAD'

# Optional options to pass to the SCM provider
# @since 0.1.0
property :scm_options,
  kind_of: Hash,
  default: Hash.new

# Releases, other than current, to keep
# @since 0.1.0
property :keep_releases,
  kind_of: Integer,
  default: 1

# Environment variables to defining when executing system commands
# @since 0.1.0
property :environment,
  kind_of: Hash,
  default: Hash.new

# Array of directories to delete when building the release artifact
# @since 0.1.0
property :purge_on_build,
  kind_of: Array,
  default: %w(log tmp/pids public/system)

# Array of directories to create when building the release artifact
# @since 0.1.0
property :create_on_build,
  kind_of: Array,
  default: %w(tmp public config)

# Hash of release >to> shared paths for which to create symlinks
# @since 0.1.0
property :symlink_on_build,
  kind_of: Hash,
  default: {
    'system' => 'public/system',
    'pids' => 'tmp/pids',
    'log' => 'log'
  }

# Name of the cache directory to create within deploy_to
# @since 0.1.0
property :cache_name,
  kind_of: String,
  default: 'repo'

# Absolute path of the cache dir to create
# @since 0.1.0
property :cache_path,
  kind_of: String,
  default: lazy { |r| ::File.join(r.deploy_to, r.cache_name) }

# Absolute path to the shared directory to create which contains resources
# which are shared amongst all releases.
# @since 0.1.0
property :shared_path,
  kind_of: String,
  default: lazy { |r| ::File.join(r.deploy_to, 'shared') }

# Absolute path to the current directory which is used to reference the
# currently live release.
# @since 0.1.0
property :current_path,
  kind_of: String,
  identity: true,
  default: lazy { |r| ::File.join(r.deploy_to, 'current') }

# Name (or git hash) of the release as provided by the SCM provider.
# The release hash will be automatically detected based on the release property
# and will be used when building releases.
# @since 0.1.0
property :release_hash,
  kind_of: String,
  required: true,
  default: lazy { |r| r.scm_provider.target_revision }

# Date of the release used when determining the release\_path and when
# logging to the revisions.log file.
# @since 1.0.0
property :release_date,
  kind_of: String,
  default: lazy { DateTime.now.strftime('%Y%m%d%H%M%S%L') }

# Absolute path to the release directory which is used to determine what the
# current_path symlink should point to.
# @since 0.1.0
property :release_path,
  kind_of: String,
  identity: true

# Absolute path to the directory containing the various releases
# @since 0.1.0
property :releases_path,
  kind_of: String,
  default: lazy { |r| ::File.join(r.deploy_to, 'releases') }

# Absolute path to the revisions.log file containing deploy history
# @since 0.1.0
property :revisions_path,
  kind_of: String,
  default: lazy { |r| ::File.join(r.deploy_to, 'revisions.log') }

# Whether to execute the migration callbacks
# @since 0.1.0
property :support_migrate,
  kind_of: [TrueClass, FalseClass],
  default: false

# Whether to execute the enabling callbacks and create the symlink
# @since 0.1.0
property :support_publish,
  kind_of: [TrueClass, FalseClass],
  default: false

# Whether to delete the existing release directory if it exists
# @since 0.1.0
property :support_force,
  kind_of: [TrueClass, FalseClass],
  default: false

# The resource class which will be responsible for downloading the cached
# copy of the source code.
# @since 0.1.0
property :scm_resource,
  kind_of: Class,
  default: Chef::Resource::Git

# An instanced provider from scm_resource.
# @since 0.1.0
def scm_provider(run_context = nil)
  current_resource = self
  resource = scm_resource.new('detect', run_context)
  resource.user         current_resource.user
  resource.group        current_resource.group
  resource.repository   current_resource.repository
  resource.revision     current_resource.revision
  current_resource.scm_options.each do |k, v|
    resource.send(k, v)
  end
  action :nothing
  resource.provider_for_action(:checkout)
end

def after_cache(&block)
  set_or_return(:after_cache, block, kind_of: Proc)
end

def before_build(&block)
  set_or_return(:before_build, block, kind_of: Proc)
end

def after_build(&block)
  set_or_return(:after_build, block, kind_of: Proc)
end

def after_updated(&block)
  set_or_return(:after_updated, block, kind_of: Proc)
end

def validate_migrate(&block)
  set_or_return(:validate_migrate, block, kind_of: Proc)
end

def before_migration(&block)
  set_or_return(:before_migration, block, kind_of: Proc)
end

def migrate_action(&block)
  set_or_return(:migrate_action, block, kind_of: Proc)
end

def after_migration(&block)
  set_or_return(:after_migration, block, kind_of: Proc)
end

def validate_publish(&block)
  set_or_return(:validate_publish, block, kind_of: Proc)
end

def before_publish(&block)
  set_or_return(:before_publish, block, kind_of: Proc)
end

def after_publish(&block)
  set_or_return(:after_publish, block, kind_of: Proc)
end

# Callback executed before an expired release is deleted.
# The Proc will receive the release_path that would be deleted.
# @since 0.3.0
def before_delete(&block)
  set_or_return(:before_delete, block, kind_of: Proc)
end

# Method returning a list of paths for all current releases
# @since 1.0.0
def current_release_paths
  ::Dir.glob(::File.join(deploy_to, '/releases/*')).sort
end

# Method returning a list of release paths which may be removed
# @since 1.0.0
def expired_release_paths
  chop = -1 - keep_releases
  current_release = if ::File.exist?(current_path)
                    then ::File.realpath(current_path)
                    end
  current_release_paths[0..chop].delete_if do |release|
    [current_release, release_path].include?(release)
  end
end

# Method returning a hash of paths and their respective release hashes
# @since 1.0.0
def current_release_revisions
  current_release_paths.map do |release_path|
    revision = release_path_revision(release_path)
    [release_path, revision]
  end.to_h
end

# Method returning the revision for a given release_path
# @since 0.1.0
def release_path_revision(release_path)
  revision_path = ::File.join(release_path, 'REVISION')
  ::File.read(revision_path).strip if ::File.exist?(revision_path)
end

# Method returning a release_path for a given revision
# @since 1.0.0
def revision_release_path(revision)
  current_release_revisions.select do |_, revision_hash|
    revision_hash == revision
  end.keys.first
end

# Method returning the default release_path for new revisions
# @since 1.0.0
def default_release_path
  ::File.join(releases_path, release_date)
end

# Load the current resource to determine which portions have changed and thus
# what code paths will be executed within the provider.
# @since 0.1.0
load_current_value do |desired|
  %w(user group repository revision scm_options).each do |p|
    send(p, desired.send(p))
  end

  %w(deploy_to shared_path current_path cache_path releases_path).each do |p|
    send(p, desired.send(p))
  end

  if desired.support_force then desired.release_path default_release_path
  elsif !desired.release_path
    detected_release_path = revision_release_path(release_hash)
    detected_release_path = default_release_path unless detected_release_path
    desired.release_path detected_release_path
  end

  current_value_does_not_exist! unless ::File.exist?(desired.release_path)

  if ::File.exist?(desired.current_path)
    current_release = ::File.readlink(desired.current_path)
    current_release = nil unless ::File.exist?(current_release)
    release_hash release_path_revision(current_release) if current_release
    release_path current_release if current_release
  else current_path 'missing'
  end

  purge_on_build begin
    desired.purge_on_build.select do |path|
      dst_path = ::File.join(desired.release_path, path)
      ::File.symlink?(dst_path) || !::File.directory?(dst_path)
    end
  end

  create_on_build begin
    desired.create_on_build.select do |path|
      ::File.directory?(::File.join(desired.release_path, path))
    end
  end

  symlink_on_build begin
    desired.symlink_on_build.select do |src, dst|
      src_path = ::File.join(desired.shared_path, src)
      dst_path = ::File.join(desired.release_path, dst)
      ::File.symlink?(dst_path) &&
        ::File.exist?(dst_path) &&
        (::File.realpath(dst_path) == src_path)
    end
  end
end

action :install do
  purge_release
  cache_release
  build_release
  migrate_release
  publish_release
  delete_releases
end

action :build do
  purge_release
  cache_release
  build_release
end

action :publish do
  migrate_release
  publish_release
  delete_releases
end

action_class do
  # Support WhyRun mode
  # @since 0.1.0
  def whyrun_supported?
    true
  end

  # Helper method to determine whether a feature is supported
  # @since 0.1.0
  def supports?(key)
    new_resource.send("support_#{key}")
  end

  # Helper method to dynamically change supported features during execution,
  # thus ensuring that hooks may trigger whether other hooks are run. For
  # instance, before_migrate could have logic which determines whether
  # migrations should be run.
  # @since 0.1.0
  def supports!(key, value)
    unless supports?(key) == value
      Chef::Log.info "#{self} changing support value #{key} to #{value}"
      new_resource.send("support_#{key}", value)
    end
  end

  # Helper method providing a shorthand to return the release_path or a join
  # of release_path elements.
  # @since 0.1.0
  def release_path(arg = nil)
    if arg.nil?
    then new_resource.release_path
    else ::File.join(new_resource.release_path, arg)
    end
  end

  # Helper method to return shortend relative paths used in resource names.
  # @since 0.1.0
  def release_name(arg = nil)
    ::File.join('release', arg)
  end

  # Helper method providing a shorthand to return the cache_path or a join
  # of cache_path elements.
  # @since 0.1.0
  def cache_path(arg = nil)
    if arg.nil?
    then new_resource.cache_path
    else ::File.join(new_resource.cache_path, arg)
    end
  end

  # Helper method providing a shorthand to return the current_path or a join
  # of current_path elements.
  # @since 0.1.0
  def current_path(arg = nil)
    if arg.nil?
    then new_resource.current_path
    else ::File.join(new_resource.current_path, arg)
    end
  end

  # Helper method to return shortend relative paths used in resource names.
  # @since 0.1.0
  def shared_name(arg = nil)
    ::File.join('shared', arg)
  end

  # Helper method providing a shorthand to return the shared_path or a join
  # of shared_path elements.
  # @since 0.1.0
  def shared_path(arg = nil)
    if arg.nil?
    then new_resource.shared_path
    else ::File.join(new_resource.shared_path, arg)
    end
  end

  # Helper method providing a shorthand to execute commands within the release
  # path context.
  # @since 0.1.0
  def run(command, &block)
    bash command do
      code  command
      user  new_resource.user
      group new_resource.group
      cwd   new_resource.release_path
      environment new_resource.environment
      instance_eval(&block) if block
    end
  end

  # Helper method providing a shorthand to create templates within the release
  # path context.
  # @since 0.1.0
  def release_template(name, &block)
    template release_name(name) do
      path  release_path(name)
      owner new_resource.user
      group new_resource.group
      instance_eval(&block) if block
    end
  end

  # Helper method providing a shorthand to create templates within the shared
  # path context.
  # @since 0.1.0
  def shared_template(name, &block)
    template shared_name(name) do
      path  shared_path(name)
      owner new_resource.user
      group new_resource.group
      instance_eval(&block) if block
    end
  end

  # Method to delete a release_path
  # @since 0.3.0
  def delete_release(release_path)
    directory "releases/#{::File.basename(release_path)}" do
      path release_path
      recursive true
      action :delete
    end
  end

  # Actions to perform when opting to force_deploy.
  # This entails deleting the current release irrespective of whether it is
  # currently live or not and then performing standard build steps.
  # @since 0.1.0
  def purge_release
    converge_by 'purge release_path' do
      directory 'delete release_path' do
        path  release_path
        owner new_resource.user
        group new_resource.group
        action :nothing
      end
    end if supports?('force')
  end

  # Actions to perform when downloading source code from the SCM Provider.
  # These will go through downloading to a cached folder, copying the cache to
  # a unique release folder, adding a RELEASE file and then running the
  # after_cache hook.
  # @since 0.1.0
  def cache_release
    converge_if_changed :release_hash do
      %w(deploy_to releases_path shared_path).each do |p|
        directory p do
          path  new_resource.send(p)
          owner new_resource.user
          group new_resource.group
        end
      end

      declare_resource(
        new_resource.scm_resource.name.split('::').last.downcase,
        new_resource.cache_path,
        create_if_missing: false
      ) do
        %w(user group repository revision).each do |p|
          send(p, new_resource.send(p))
        end
        new_resource.scm_options.each do |k, v|
          send(k, v)
        end
      end

      common_deploy_directory_copy release_path do
        source      cache_path
        owner       new_resource.user
        group       new_resource.group
        exclude     '.git'
      end

      file 'save release revision' do
        path    release_path('REVISION')
        owner   new_resource.user
        group   new_resource.group
        content new_resource.release_hash
      end

      converge_by 'execute after_cache' do
        instance_eval(&new_resource.after_cache)
      end if new_resource.after_cache
    end
  end

  # Actions to perform when preparing a cached release for deployment.
  # This includes executing before_build callbacks, deleting original source
  # folders, creating new folders, adding symlinks to folders shared amongst
  # all releases, and then executing the after_build hook.
  # @since 0.1.0
  def build_release
    converge_by 'execute before_build' do
      instance_eval(&new_resource.before_build)
    end if new_resource.before_build

    converge_if_changed :purge_on_build do
      new_resource.purge_on_build.each do |dst|
        directory release_name(dst) do
          path release_path(dst)
          recursive true
          action :delete
          only_if do
            ::File.directory?(release_path(dst))
          end
          not_if do
            ::File.symlink?(release_path(dst))
          end
        end
      end
    end

    converge_if_changed :create_on_build do
      new_resource.create_on_build.each do |dst|
        directory release_name(dst) do
          path  release_path(dst)
          owner new_resource.user
          group new_resource.group
          not_if do
            ::File.symlink?(release_path(dst))
          end
        end
      end
    end

    converge_if_changed :symlink_on_build do
      new_resource.symlink_on_build.each do |src, dst|
        link release_name(dst) do
          target_file release_path(dst)
          to shared_path(src)
          only_if do
            !::File.exist?(release_path(src)) ||
            ::File.symlink?(release_path(src))
          end
        end
      end
    end

    converge_by 'execute after_build' do
      instance_eval(&new_resource.after_build)
    end if new_resource.after_build

    converge_if_changed :release_hash do
      converge_by 'execute after_updated' do
        instance_eval(&new_resource.after_updated)
      end if new_resource.after_updated
    end
  end

  # Actions to perform when executing database or system migrations.
  # This includes executing the before_migration callback, then executing the
  # migrate_action callback and lastly executing the after_migration callback.
  # @since 0.1.0
  def migrate_release
    converge_by 'execute validate_migrate' do
      instance_eval(&new_resource.validate_migrate)
    end if new_resource.validate_migrate

    converge_if_changed :release_path, :current_path do
      converge_by 'execute before_migration' do
        instance_eval(&new_resource.before_migration)
      end if new_resource.before_migration

      converge_by 'execute migrations' do
        instance_eval(&new_resource.migrate_action)
      end if new_resource.migrate_action

      converge_by 'execute after_migration' do
        instance_eval(&new_resource.after_migration)
      end if new_resource.after_migration
    end if supports?('migrate')
  end

  # Actions to perform when enabling or replacing the release.
  # This includes performing the before_publish callback, then creating the
  # current_path symlink and lastly calling the after_publish callback.
  # @since 0.1.0
  def publish_release
    converge_by 'execute validate_publish' do
      instance_eval(&new_resource.validate_publish)
    end if new_resource.validate_publish

    converge_if_changed :release_path, :current_path do
      converge_by 'execute before_publish' do
        instance_eval(&new_resource.before_publish)
      end if new_resource.before_publish

      converge_by "publish #{new_resource.release_hash}" do
        link current_path do
          to release_path
        end

        ruby_block 'log release_hash' do
          block do
            message = "Revision #{new_resource.revision}" \
              " (at #{new_resource.release_hash})" \
              " deployed on #{new_resource.release_date}\n"

            ::File.open(new_resource.revisions_path, 'a') do |f|
              f.write("#{message}")
            end
          end
        end
      end

      converge_by 'execute after_publish' do
        instance_eval(&new_resource.after_publish)
      end if new_resource.after_publish
    end if supports?('publish')
  end

  # Actions to perform when cleaning up previous releases
  # @since 0.1.0
  def delete_releases
    converge_by 'delete previous releases' do
      new_resource.expired_release_paths.each do |release_path|
        if new_resource.before_delete
          instance_exec(release_path, &new_resource.before_delete)
        end
        delete_release(release_path)
      end
    end
  end
end
