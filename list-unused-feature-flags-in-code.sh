#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

# Mandatory arguments
LD_AUTH_TOKEN=""
PROJECT=""

# Optional arguments
OUTPUT_FILE="unused-feature-flags.txt"
ENVIRONMENT="production"
LIMIT="5000"
HELP="false"

for i in "$@"
do
  case $i in
      # Required arguments
      -t=*|--token=*)
      LD_AUTH_TOKEN="${i#*=}"
      shift # past argument=value
      ;;
      -o=*|--output-file=*)
      OUTPUT_FILE="${i#*=}"
      shift # past argument=value
      ;;
      -e=*|--env=*)
      ENVIRONMENT="${i#*=}"
      shift # past argument=value
      ;;
      -p=*|--project=*)
      PROJECT="${i#*=}"
      shift # past argument=value
      ;;
      -l=*|--limit=*)
      LIMIT="${i#*=}"
      shift # past argument=value
      ;;
      -h=*|--help=*|-h|--help)
      HELP="true"
      shift # past argument=value
      ;;
      --default)
      shift # past argument with no value
      ;;
      *)
        # unknown option
      ;;
  esac
done

setup() {

  if [ "$HELP" == "true" ]; then
    cat << EOM
List unused Feature Flags in Code
and checks for cleaned up feature flags in LaunchDarkly, 
so they can be removed from your codebase

Dependency Requirements (other than LSB commands)
  - curl
  - git
  - jq

This script queries LaunchDarkly for feature flags with client SDK on (frontend/backend flags).
Then it searches for the received flags that are not in this codebase in your codebase 
checking them using GIT.

Usage:
  Pass '--token' with a valid API token (see https://docs.launchdarkly.com/home/account-security/api-access-tokens) 
  and run as following

  $ npm run list-unused-feature-flags-in-code -- --help 
  $ npm run list-unused-feature-flags-in-code -- --token=<token> 

  Arguments:
    - '-t|--token'(required): LaunchDarkly API Token. It's required for LaunchDarkly API communication.
    - '-p|--project'(required): LaunchDarkly project containing flags
    - '-h|--help'(optional): It shows the help command with the steps to run this script
    - '-o|--output'(optional): Path to output file, which will contain a list of all supect flags (defaults to 'flags-for-removal.txt')
    - '-e|--env'(optional): LaunchDarkly enviroment containing flags (defaults to 'production')
    - '-l|--limit'(optional): Limit the number of results from LaunchDarkly (defaults to '5000')


EOM
    exit 0
  fi

  if [ "$LD_AUTH_TOKEN" == "" ]; then
    echo "LD_AUTH_TOKEN env variable with the API Auth Token is not available."
    echo "For more details, please check https://docs.launchdarkly.com/home/account-security/api-access-tokens"
    exit 1
  fi

  if [ "$PROJECT" == "" ]; then
    echo "PROJECT env variable should be informed via '-p' or '--project'."
    echo ""
    exit 1
  fi

  # Check if files exist. In case of yes, removes the previous file
  if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
  fi
}

tearDown() {
  if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
  fi
}

getAllFeatureFlags() {
  now=$(date +%s000)
  curl --request GET \
    --url "https://app.launchdarkly.com/api/v2/flags/$PROJECT?limit=$LIMIT&offset=0&summary=false&env=$ENVIRONMENT" \
    --header "authorization: $LD_AUTH_TOKEN" \
    --header 'ld-api-version: beta' \
    | jq -r ".items[] | select(.creationDate < $now) | .key"
}

checkForFeatureFlagsInCodebase() {
  while IFS= read -r line; do
    echo "Checking feature flag: '$line'"
    grepResult=$(git grep -r "$line" . || true)

    if [ -z "$grepResult" ]; then
      echo "    Feature flag is not in current code"
      gitlogResult=$(git log -S "$line" --stat --since="$cutoffTime" --patch)

      if [ -z "$gitlogResult" ]; then
        echo "    Feature flag was not modified in code since $cutoffTime"
        echo "    Feature flag is a removal candidate: '$line'"
        echo "$line" >> "$OUTPUT_FILE"
      else
        echo "    Feature flag was recently modified in code, no action"
      fi
    else
        echo "    Feature flag is currently in code, no action"
    fi
  done <<< "$1"
}

main() {

  setup
  tearDown


  cutoffTime=$(date +%Y-%m-%d)

  echo "Starting search for unused feature flags that might be removed until ($(date))"
  echo ""
  echo "Getting frontend feature flags from LaunchDarkly"
  featureFlags=$(getAllFeatureFlags)

  echo ""
  echo "Checking Git repository for feature flags"
  checkForFeatureFlagsInCodebase "$featureFlags"

  echo ""
  echo "All done!"
}

# `time` is the default command available on CLI.
# More details in this link https://man7.org/linux/man-pages/man1/time.1.html
time main