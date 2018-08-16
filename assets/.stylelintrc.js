/* eslint-disable key-spacing */
module.exports = {
  estends: 'stylelint-config-standard',
  plugins: [
    'stylelint-scss',
  ],
  rules: {
    'at-rule-no-unknown': null, // disabled in favor of SCSS-aware version below
    'at-rule-no-vendor-prefix': true,
    'at-rule-empty-line-before': ['always', {
      except: [
        'blockless-after-same-name-blockless',
        'first-nested',
      ],
      ignore: ['after-comment'],
      ignoreAtRules: ['return'],
    }],
    'color-hex-length': 'long',
    'declaration-block-single-line-max-declarations': 2,
    'font-family-name-quotes': 'always-where-recommended',
    indentation: [2, {
      indentInsideParens: 'once-at-root-twice-in-block',
    }],
    'max-line-length': [80, {
      ignorePattern: '/stylelint-disable-(next-)?line/',
    }],
    'media-feature-name-no-vendor-prefix': true,
    'property-no-vendor-prefix': true,
    'rule-empty-line-before': ['always-multi-line', {
      except: ['first-nested'],
      ignore: ['after-comment', 'inside-block'],
    }],
    'selector-max-id': 0,
    'selector-no-vendor-prefix': true,
    'value-no-vendor-prefix': true,

    'scss/at-else-closing-brace-newline-after': 'always-last-in-chain',
    'scss/at-else-closing-brace-space-after': 'always-intermediate',
    'scss/at-else-empty-line-before': 'never',
    'scss/at-else-if-parentheses-space-before': 'always',
    'scss/at-extend-no-missing-placeholder': true,
    'scss/at-function-parentheses-space-before': 'never',
    'scss/at-if-closing-brace-newline-after': 'always-last-in-chain',
    'scss/at-if-closing-brace-space-after': 'always-intermediate',
    'scss/at-import-no-partial-leading-underscore': true,
    'scss/at-mixin-argumentless-call-parentheses': 'never',
    'scss/at-mixin-named-arguments': ['always', {
      ignore: ['single-argument'],
    }],
    'scss/at-mixin-parentheses-space-before': 'never',
    'scss/at-rule-no-unknown': true,
    'scss/dollar-variable-colon-newline-after': 'always-multi-line',
    'scss/dollar-variable-colon-space-after': 'at-least-one-space',
    'scss/dollar-variable-colon-space-before': 'never',
    'scss/dollar-variable-no-missing-interpolation': true,
    // 'scss/double-slash-comment-whitespace-inside': 'always',
    'scss/media-feature-value-dollar-variable': 'always',
    'scss/no-duplicate-dollar-variables': true,
    // 'scss/operator-no-newline-before': true,
    // 'scss/operator-no-unspaced': true,
    'scss/partial-no-import': true,
    'scss/selector-no-redundant-nesting-selector': true,
  },
};
