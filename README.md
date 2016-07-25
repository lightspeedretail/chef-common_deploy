# common_deploy cookbook

A cookbook which provides tools to help deploy simple applications in a standardized way via node attributes. This is designed to be used with PolicyFiles and the suite of `common_*` cookbooks so that applications may be deployed without necessarily requiring a dedicated cookbook.

*Warning*: This cookbook is not yet ready for public consumption

# Requirements

This cookbook requires *Chef 12.7.0* or later.

# Platform

Any

# Attributes

### Top Level
- `common_deploy`.`default`: This provides the default attributes which will be used as the base to merge specific applications on top of.
- `common_deploy`.`*`: Each application will be configured within a self contained hash so as to ensure that all of it's required configurations are stored in one place. Below this level, key => hash pairs will exist to describe additional lwrps to generate.

### Application Level

- `order`: The optional ordering in which we will deploy applications, defaults to *100*.
- `configuration`: A free-form hash used to provide more global attributes to templates. These will serve as the base onto which specific template variables will be merged.

# Libraries

- `CommonDeploy::Applications`: A helper library providing the business logic behind how we iterate over applications and apply the default attributes.

