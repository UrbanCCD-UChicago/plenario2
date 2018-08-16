/* eslint-disable key-spacing */
module.exports = {
  extends: ['eslint:recommended', 'airbnb-base'],
  env: {
    browser: true,
    node: true,
  },
  rules: {
    'key-spacing': [
      'error',
      {
        beforeColon: false,
        afterColon: true,
        align: 'value',
      },
    ],
    'import/no-extraneous-dependencies': ['error', { devDependencies: true }],
  },
};
