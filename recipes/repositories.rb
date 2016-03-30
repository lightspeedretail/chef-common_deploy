
# Iterate through the common_deploy hash, returning the key:value pairs in the
# order that they are required, with the default namespace overlayed.
#
# On each invocation, create a common_deploy_repository resource if required.
# @since 0.1.0
CommonDeploy::Applications.each do |application, hash|
  if repository = hash.fetch(:repository, {})
    common_deploy_repository application do
      common_properties repository
    end
  end
end

