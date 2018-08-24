/* eslint-disable key-spacing */
module.exports = {
  extends: ['eslint:recommended', 'plugin:vue/recommended', 'airbnb-base'],
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
    // TODO: Enable once eslint-plugin-vue hits v5
    // 'vue/component-name-in-template-casing': 'error',
    'vue/html-self-closing': ['error', { html: { normal: 'never' } }],
    'vue/max-attributes-per-line': ['error', { multiline: { allowFirstLine: true } }],
  },
};
