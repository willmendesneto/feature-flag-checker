# 🚀 Feature Flag Checker 🚀

Sample code showing how to check unused Feature Flags in your codebase

## Setup

### Create a LaunchDarkly account

Firstly, make sure you have a LaunchDarkly account. In your account, create a project and pass the SDK value into `LD_SDK_KEY` environment variable.

> You can find the SDK key for your specific project in https://app.launchdarkly.com/settings/projects

### 💻 Steps to run

- git clone https://github.com/willmendesneto/feature-flag-checker.git
- cd feature-flag-checker
- nvm use
- npm install
- `LD_SDK_KEY=<your-sdk-key> npm start`

### Running feature flag unused check

You can check all the available params by running the command passing `--help`

```bash
npm run list-unused-feature-flags-in-code -- --help
```

Some of the params are optional. However, `--token` and `--project` are _mandatory_.

```bash
npm run list-unused-feature-flags-in-code -- \
  -p=<launchdarkly-project-name> \
  -e=<lauchdarkly-environment> \
  -l=<lauchdarkly-api-limit> \
  -o=<output-file> \
  -t=<your-lauchdarkly-api-sdk>
```

E.G.

> Replace `<your-lauchdarkly-api-sdk>` with a valid API token. You can find more details about it in https://docs.launchdarkly.com/home/account-security/api-access-tokens

```bash
npm run list-unused-feature-flags-in-code -- \
  -p=feature-flag-checker \
  -e=production \
  -l=3000 \
  -o=unused-feature-flags-in-code.txt \
  -t=<your-lauchdarkly-api-sdk>
```

## Author

**Wilson Mendes (willmendesneto)**

- <https://twitter.com/willmendesneto>
- <http://github.com/willmendesneto>
