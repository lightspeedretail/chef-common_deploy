
# Iterate through the common_deploy hash, returning the key:value pairs in the
# order that they are required, with the default namespace overlayed.
#
# On each invocation, create a common_deploy_template resource if required.
# @since 0.1.0
CommonDeploy::Applications.each do |application_name, hash|
	if templates = hash.fetch(:templates, nil)
		templates.each do |name, template_hash|
			common_deploy_template name do
        application application_name
        configs CommonDeploy::Configs.fetch(application_name)
        common_properties template_hash
      end
    end
  end
end

