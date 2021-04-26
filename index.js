const assert = require('assert');
const LaunchDarkly = require('launchdarkly-node-server-sdk');

// Check if the variable was passed on
assert(process.env.LD_SDK_KEY, 'env var "LD_SDK_KEY" should be passed to the command');

const featureFlagKey = 'is-app-enabled';
const config = {
  key: `user-${Date.now()}`,
};

const ldClient = LaunchDarkly.init(process.env.LD_SDK_KEY);

const main = async () => {
  try {
    await ldClient.waitForInitialization();

    console.log('SDK successfully initialized!');

    const flagValue = await ldClient.variation(featureFlagKey, config, false);
    console.log(`Feature flag '${featureFlagKey}' is '${flagValue}'`);

    ldClient.flush(() => {
      console.info('Flushing connections ...');
      ldClient.close(() => {
        console.info('Shutting down ...');
      });
    });
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

process.setMaxListeners(0);

const gracefulShutdown = () => {
  ldClient.flush(() => {
    console.info('Flushing connections ...');
    ldClient.close(() => {
      console.info('Shutting down ...');
      process.exit(1);
    });
  });
};

// listen for TERM signal .e.g. kill
process.on('SIGTERM', gracefulShutdown);
// listen for INT signal e.g. Ctrl-C
process.on('SIGINT', gracefulShutdown);

main();
