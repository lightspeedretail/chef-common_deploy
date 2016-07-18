
# Iterate through the common_deploy hash, returning the key:value pairs in the
# order that they are required, with the default namespace overlayed.
#
# On each invocation, create package resources if required.
# @since 0.1.0
CommonDeploy::Applications.each do |_, hash|
  next unless hash.key?('packages')

  hash['packages'].each do |name, package_hash|
    properties = case package_hash
                 when true then { 'action' => 'install' }
                 when false then { 'action' => 'remove' }
                 else package_hash
                 end

    package name do
      common_properties(properties)
    end
  end
end
