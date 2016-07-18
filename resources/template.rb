# The deploy_template resource is used to deploy an application template
# and incorporates some of the application logic that is specific to the
# deploy_ cookbooks.

resource_name :common_deploy_template

# Include file permission mixin
include Chef::Mixin::Securable

# Path of the templated file
property :path,
  kind_of: String,
  name_property: true,
  identity: true

# Name of the application used in attribute namespaces
property :application,
  kind_of: String,
  required: true

# Source of the template
property :source,
  kind_of: [String, Array],
  desired_state: false

# If not local, the cookbook that owns the template
property :cookbook,
  kind_of: String

# Indicate that the source is the path to a file on disk
property :local,
  kind_of: [TrueClass, FalseClass]

# Indicate that the template contains passwords
property :sensitive,
  kind_of: [TrueClass, FalseClass]

# Variables to make available to the template
# - These should be considered as local overrides to the attributes provided
# by the `configs` property.
property :variables,
  kind_of: [Hash],
  default: Hash.new

# Attribute namespace to make available to the template
# - These will automatically load from `node[:deploy_configs]` based on the
# application name.
property :configs,
  kind_of: [Hash],
  default: lazy { |r| Deploy::Config.application(r.application) }

# Ensure that the resource is applied regardless of whether we are in why_run
# or standard mode.
#
# Refer to chef/chef#4537 for this uncommon syntax
action_class do
  def whyrun_supported?
    true
  end
end

action :create do
  # Create a template variables hash which is equivalent to a merge of :
  # - node[:deploy_configs][#{app_name}]
  # - new_resource.variables
  template_variables = Chef::Mixin::DeepMerge
    .merge(new_resource.variables, new_resource.configs)

  r = template new_resource.name
  r.variables template_variables

  %w(path owner group mode source cookbook local sensitive).each do |key|
    r.send(key.to_sym, new_resource.send(key.to_sym))
  end
end

action :delete do
  template new_resource.name do
    path new_resource.path
    action :delete
  end
end
