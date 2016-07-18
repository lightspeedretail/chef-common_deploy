default[:common_deploy].tap do |config|
  # Namespace for default attributes which will provide a baseline for all
  # applications deployed here.
  #
  # The contents of this hash should be keyed with application names where the
  # data is a hash of resources to create and which are provided by this
  # cookbook.
  #
  # The contents of :default should be the same, in this case providing the
  # default values for all further resources.
  #
  # @example
  # ```json
  # {
  #   "common_deploy": {
  #     "default": {
  #       "configuration": {
  #         "database": {
  #           "host": "db.domain.com"
  #         }
  #       },
  #       "repository": {
  #         "revision": "production",
  #         "user": "www-data",
  #         "group": "www-data"
  #       },
  #     },
  #     "frontend": {
  #       "repository": {
  #         "destination": "/var/www/frontend",
  #         "repository": "git://github.com/something/frontend"
  #       }
  #     }
  #   }
  # }
  # ```
  #
  # @since 0.1.0
  config[:default] ||= {}
end
