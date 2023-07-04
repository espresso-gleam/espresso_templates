// TODO figure out how to get gleam to read ts or something
const fs = require("fs");
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
