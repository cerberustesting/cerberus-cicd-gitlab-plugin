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

# Manual config.

Alternativly, you can use a direct configuration using any standard docker image that support curl and jq:

```Dockerfile

FROM alpine

RUN apk add --no-cache curl jq

````

With the following Gitlab configuration using the given variables:

- ${CI_PROJECT_NAME} : Campaign name to be configured inside Cerberus (Under: Run / Campaign).
- ${CERBERUS_TOKEN} : APIKEY of a service account to be created and configured inside Cerberus (Under: Administration / User Management).
- ${CI_JOB_ENVIRONMENT} : environment where the campaign must be executed (must be the same as the ones configures inside Cerberus Under: Administration / Invariants).
- ${CERBERUS_HOST} : Host of your Cerberus instance ex : https://prod.cerberus-testing.com
- ${CI_JOB_STARTED_AT} : Timestamps in order to make the campaign execution unique.

```yaml

#######################
# Cerberus validation #
#######################

.cerberus:
  image: path_to_alpine_image
  stage: validate
  variables:
    CERBERUS_TAG: ${CI_PROJECT_NAME}_${CI_JOB_STARTED_AT}
  script:
    - curl -s --request POST --url "${CERBERUS_HOST}/AddToExecutionQueueV003" -d "campaign=${CI_PROJECT_NAME}" -d "environment=${CI_JOB_ENVIRONMENT}" -d "tag=${CERBERUS_TAG}" -H "apikey:${CERBERUS_TOKEN}" -w "\n"
    - echo "${CERBERUS_HOST}/ReportingExecutionByTag.jsp?Tag=${CERBERUS_TAG}"
    - while true; do
      result=$(curl -s --request POST --url "${CERBERUS_HOST}/ResultCIV004" -d "tag=${CERBERUS_TAG}" -H "apikey:${CERBERUS_TOKEN}"| jq -r ".result");
      case ${result} in
      PE) sleep 5 ;;
      OK) exit 0 ;;
      *) exit 1 ;;
      esac;
      done
  when: manual

cerberus_development:
  extends: .cerberus
  environment: development
  only:
    - develop

cerberus_staging:
  extends: .cerberus
  environment: staging
  only:
    - main

cerberus_production:
  extends: .cerberus
  environment: production
  only:
    - main

````


