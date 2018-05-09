/* eslint-disable import/no-extraneous-dependencies */

const merge = require("webpack-merge");
const UglifyJSPlugin = require("uglifyjs-webpack-plugin");

const common = require("./webpack.common");

module.exports = merge(common, {
  devtool: "source-map",
  plugins: [
    new UglifyJSPlugin({
      sourceMap: true
    })
  ]
});
