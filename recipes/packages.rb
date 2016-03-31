
# Iterate through the common_deploy hash, returning the key:value pairs in the
# order that they are required, with the default namespace overlayed.
#
# On each invocation, create package resources if required.
# @since 0.1.0
CommonDeploy::Applications.each do |application, hash|
  if packages = hash.fetch(:packages, nil)
    packages.each do |name, hash|
      hash = case hash
             when true then { action: "install" }
             when false then { action: "remove" }
             end

      package name do
        common_properties(hash)
      end
    end
  end
end

