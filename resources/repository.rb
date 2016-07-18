
# The deploy_repository resource is used to deploy git code repositories and
# execute any relevant pre/post deploy actions. For all intents and purposes,
# this is a wrapper around the `git` resource which provides some additional
# functionality.
#

resource_name :common_deploy_repository

# The destination folder where to deploy (git.destination)
property :destination,
  kind_of: String,
  name_attribute: true

# The repository url to deploy (git.repository)
property :repository,
  kind_of: String,
  required: true

# The revision to deploy (git.revision)
# - This may be a branch, tag or commit
property :revision,
  kind_of: String

# The repository owner (git.user)
property :user,
  kind_of: String

# The repository owning group (git.group)
property :group,
  kind_of: String,
  default: lazy(&:user)

# The repository depth (git.depth) for shallow cloning
property :depth,
  kind_of: Integer

# Whether to enable git submodules (git.enable_submodules)
property :enable_submodules,
  kind_of: [TrueClass, FalseClass],
  default: true

# Whether to enable git to checkout (git.enable_checkout)
property :enable_checkout,
  kind_of: [TrueClass, FalseClass],
  default: true

# An optional ssh wrapper to use (git.ssh_wrapper)
property :ssh_wrapper,
  kind_of: String

# An optional hash containing environment variables to define before executing
# pre/post deploy hooks.
property :environment,
  kind_of: Hash,
  default: {}

# An optional array of shell commands to run prior to modifying the git
# repository. These will only fire if the git repository would change.
property :before_deploy,
  kind_of: Array,
  default: []

# An optional array of shell commands to run after modifying the repository.
# These will only fire if the git repository was changed.
property :after_deploy,
  kind_of: Array,
  default: []

# Ensure that the resource is applied regardless of whether we are in why_run
# or standard mode.
#
# Refer to chef/chef#4537 for this uncommon syntax
action_class do
  def whyrun_supported?
    true
  end
end

action :sync do
  directory new_resource.destination do
    user new_resource.user
    group new_resource.group
    recursive true
  end

  new_resource.before_deploy.each do |string|
    execute string do
      cwd new_resource.destination
      command string
      environment new_resource.environment
      action :nothing
      subscribes :run, resource(git: new_resource.destination), :before
    end
  end

  git new_resource.destination do
    repository  new_resource.repository
    revision    new_resource.revision
    user        new_resource.user
    group       new_resource.group
    ssh_wrapper new_resource.ssh_wrapper if new_resource.ssh_wrapper
    enable_submodules new_resource.enable_submodules
    enable_checkout   new_resource.enable_checkout
    action :sync
  end

  new_resource.after_deploy.each do |string|
    execute string do
      cwd new_resource.destination
      command string
      environment new_resource.environment
      action :nothing
      subscribes :run, resources(git: new_resource.destination), :immediately
    end
  end
end
