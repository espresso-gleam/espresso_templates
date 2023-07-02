// From here
// https://github.com/jim/esbuild-plugin-gleam
// Modified to work with newere gleam versions

import { readFile } from "fs/promises";
import { spawnSync } from "child_process";
import { cwd, chdir } from "process";
import { parse } from "toml";
import { basename } from "path";

const PLUGIN_NAME = "esgleam";

const convertMessage = (message) => ({
  id: message,
  pluginName: PLUGIN_NAME,
  location: null,
  notes: [],
  detail: null,
  text: `\n${PLUGIN_NAME}:\n${message}`,
});

const compile = (gleam_dir, extra_args) => {
  const pwd = cwd();
  chdir(gleam_dir);
  const gleam = spawnSync("gleam", [
    "build",
    "--target",
    "javascript",
    ...extra_args,
  ]);

  if (cwd() !== pwd) {
    chdir(pwd);
  }

  return { out: gleam.stdout, stderr: gleam.stderr, err: gleam.error };
};

const load_gleam_name = async (gleam_dir) => {
  const contents = await readFile(`${gleam_dir}/gleam.toml`, "utf8");
  return parse(contents).name;
};

export default function esgleam(opts) {
  return {
    name: PLUGIN_NAME,
    setup(build) {
      build.onLoad({ filter: /\.gleam$/ }, async (args) => {
        const project_root = opts?.project_root ?? ".";
        const compile_args = opts?.compile_args ?? [];

        const filename = basename(args.path).replace(".gleam", ".mjs");
        const project_name = await load_gleam_name(project_root);
        const build_path = `${project_root}/build/dev/javascript/${project_name}`;

        const { out: _, stderr, err } = compile(project_root, compile_args);
        if (stderr && stderr.length > 0) {
          return { errors: [convertMessage(stderr.toString())] };
        }

        if (err && err?.message.length > 0) {
          return {
            errors: [convertMessage(`Error running gleam: ${err.message}`)],
          };
        }

        let contents = await readFile(`${build_path}/${filename}`, "utf8");
        if (opts?.main_function !== undefined) {
          contents += `\n\n${opts.main_function}();`;
        }

        return { contents, loader: "js", resolveDir: build_path };
      });
    },
  };
}
