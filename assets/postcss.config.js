/* eslint-disable global-require */

module.exports = {
  plugins: [
    require('postcss-import'),
    // PostCSS includes Autoprefixer, but ESLint tries to resolve it against the
    // standalone NPM package (which isn't in our dependencies list)
    // eslint-disable-next-line import/no-extraneous-dependencies
    require('autoprefixer'),
  ],
};
