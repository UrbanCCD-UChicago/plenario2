const merge = require('webpack-merge');
const commonFunc = require('./webpack.common');
const StyleLintPlugin = require('stylelint-webpack-plugin');

module.exports = (_, argv) => {
  const common = commonFunc(null, argv);
  const dev = {
    mode:    'development',
    devtool: 'source-map',
    stats:   {
      all:      false,
      assets:   true,
      colors:   true,
      warnings: true,
      errors:   true,
    },
    plugins: [
      // Lint all of our style files (also used in prod with different config)
      new StyleLintPlugin({
        files: 'src/**/*.{css,scss,sass,vue}',
      }),
    ],
  };
  return merge(common, dev);
};
