import fs from "fs";
import path from "path";
import chokidar from "chokidar";
import { spawnSync } from "child_process";
// Taken as reference from the gleam/javascript lib
// this magically imports the build/<env>/javascript/gleam.mjs
// file that has all the gleam types defined.
import * as gleam from "./gleam.mjs";

export function stdin() {
  return fs.readFileSync(process.stdin.fd).toString();
}

export function format(input) {
  const child = spawnSync("gleam", ["format", "--stdin"], {
    input,
    encoding: "utf-8",
  });

  if (child.stderr) return new gleam.Error(child.stderr.toString());
  return new gleam.Ok(child.stdout.toString());
}

export function args() {
  return process.argv.slice(2);
}

export function read_file(path) {
  return fs.readFileSync(path).toString();
}

export function write_file(path, contents) {
  return fs.writeFileSync(path, contents);
}

export function base_name(filePath) {
  return path.basename(filePath, path.extname(filePath));
}

export function dirname(filePath) {
  return path.dirname(filePath);
}

export function watch(glob, callback) {
  console.log("Watching for changes to", JSON.stringify(glob, null, 2));
  chokidar.watch(glob).on("change", (file) => {
    callback(path.resolve(file));
  });
}

export function test() {
  return new gleam.Error("Not implemented yet");
}
