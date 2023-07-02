// TODO figure out how to get gleam to read ts or something
const fs = require("fs");

exports.stdin = function () {
  return fs.readFileSync(process.stdin.fd).toString();
};
