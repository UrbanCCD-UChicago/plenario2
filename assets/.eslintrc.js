module.exports = {
  parser: "babel-eslint",
  extends: ["airbnb-base", "prettier"],
  plugins: ["prettier"],
  env: {
    browser: true,
    node: true
  },
  rules: {
    "import/no-extraneous-dependencies": ["error", {"devDependencies": true}],
    "prettier/prettier": "error"
  }
};
