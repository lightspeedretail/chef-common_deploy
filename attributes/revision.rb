default['common_deploy']['revision'].tap do |config|
  # @example ```json
  # {
  #   "common_deploy": {
  #     "revision": {
  #       "api": {
  #         "repository": {
  #           "user": "",
  #           "group": ""
  #         },
  #         "revisions": {
  #           "sha-256": bool
  #         }
  #       }
  #     }
  #   }
  # }
end
