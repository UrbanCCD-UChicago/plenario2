/* eslint-disable import/no-extraneous-dependencies */

const merge = require('webpack-merge');
const common = require('./webpack.common');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

module.exports = merge(common, {
  devtool: 'inline-source-map',
  stats: {
    colors: true,
  },
  performance: {
    hints: false,
  },
  plugins: [
    new BundleAnalyzerPlugin()
  ]
});
