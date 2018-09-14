const merge = require('webpack-merge');
const commonFunc = require('./webpack.common');
const StyleLintPlugin = require('stylelint-webpack-plugin');

module.exports = (_, argv) => {
  const common = commonFunc(null, argv);
  const prod = {
    mode:    'production',
    devtool: 'none',
    stats:   {
      all:          false,
      assets:       true,
      errors:       true,
      errorDetails: true,
      warnings:     true,
      version:      true,
    },
    optimization: {
      splitChunks: { chunks: 'all' },
    },
    performance: {
      // Hard error to avoid outputting a huge file by accident. We specifically only consider asset
      // types that would have been productively handled by Webpack so we don't error out just
      // because a key photo or an error message GIF is a little bit too large. NOTE: rather
      // generous limits are set here, since this is a hard-pass filter, but in general we want to
      // shoot to keep our bundled assets in the 250kB range.
      hints:             'warning',
      assetFilter:       fn => /\.(js|css|html?|svg|png)$/.test(fn),
      maxAssetSize:      524288,
      maxEntrypointSize: 1048576,
    },
    plugins: [
      // Lint all of our style files (also used in dev with different config)
      new StyleLintPlugin({
        files:      'src/**/*.{css,scss,sass,vue}',
        emitErrors: true,
      }),
    ],
  };

  return merge(common, prod);
};
