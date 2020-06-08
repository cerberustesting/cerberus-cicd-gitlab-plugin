# Cerberus CI Plugin for Gitlab

This plugin allows to run Cerberus campaigns inside a CI/CD pipeline with Gitlab.

It's written in Ruby, the native language of Gitlab and, similarly to the Jenkins plugin, it calls the latest AddToExecutionQueue servlet with the all parameters provided by Gitlab Runner.

# Usage

This script can take several arguments as an input, with the following mandatory:

`ruby cerberus.rb --campaign <your-campaign> --tag <your-tag> --cerberus_host <your-cerberus-host>`

- `<your-cerberus-host>` url of your cerberus application (ex: https://prod.cerberus-testing.org)
- `<your-campaign>` campaign name
- `<your-tag>` name of the desired tag (must not be already used in order to avoid report errors)

This assume the target campaign is fully set up.

You can also check all the arguments by `ruby cerberus.rb --help`
