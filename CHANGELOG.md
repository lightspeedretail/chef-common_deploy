common\_deploy
============

v1.0.0
------
* Breaking Change
  * Instead of creating releases as releases/$release\_hash$ we create releases/$timestamp as to support re-deploying via force\_deploy.
* Add a common\_deploy\_directory\_copy resource which will copy the contents of one folder to another. 

v0.3.2
------
* Resolve issue detecting broken symlinks

v0.3.0
------
* Bugfix: Remove extra newline in revision log
* Refactor release copy to ignore the .git folder
* Add new before_delete callback and refactor delete_releases

v0.2.2
------
* Bugfix

v0.2.1
------
* Add additional guards to the `cp`, purge and build resources to ensure that
we can better survive rollbacks.

v0.2.0
------
* Remove template and repository resources which quite simply don't bring anything to the game in their current state. Needless wrappers are needless.
* Rename default revision action to install from deploy
* Rewrite CommonDeploy::Application library to streamline things


v0.1.10
-------
* Bugfix issue with deployments

v0.1.9
------
* Add newline to the revisions file

v0.1.8
------
* Add after\_updated callback to revision resource

v0.1.7
------
* Upgrade run helpers to use bash rather than execute and thus ensure that we support commands such as npm and rbenv that may otherwise have issues.

v0.1.6
------
* Do it more betterly

v0.1.5
------
* Bugfix helpers not creating when no block is provided
* Fix issue where SCM provider is not instantiating on older chefs

v0.1.4
------
* Rubocop fixes
* Stylistic updates

v0.1.3
------
* Added new revision resource
* Renamed resource files

v0.1.2
------
* Initial

