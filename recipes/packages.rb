
# Iterate through the common_deploy hash, returning the key:value pairs in the
# order that they are required, with the default namespace overlayed.
#
# On each invocation, create package resources if required.
# @since 0.1.0
CommonDeploy::Applications.each do |application, package_list|
  if packages = package_list.fetch(:packages, nil)
    packages.each do |name, package_properties|
      package_properties = case package_properties
             when true then { action: 'install' }
             when false then { action: 'remove' }
             else package_properties
             end

      package name do
        common_properties(package_properties)
      end
    end
  end
end
