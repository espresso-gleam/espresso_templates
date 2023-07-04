const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

exports.stdin = function () {
  return fs.readFileSync(process.stdin.fd).toString();
};

exports.format = function (input) {
  const child = spawnSync("gleam", ["format", "--stdin"], {
    input,
    encoding: "utf-8",
  });

  console.log(child.stderr.toString());
  return child.stdout.toString();
};

exports.args = function () {
  return process.argv.slice(2);
};

exports.read_file = function (path) {
  return fs.readFileSync(path).toString();
};

exports.write_file = function (path, contents) {
  return fs.writeFileSync(path, contents);
};

exports.base_name = function (filePath) {
  return path.basename(filePath, path.extname(filePath));
};
