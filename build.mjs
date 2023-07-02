// add to your esbuild config file
import esbuild from "esbuild";
import esgleam from "./esgleam/esgleam.mjs";

esbuild
  .build({
    platform: "node",
    entryPoints: ["./src/espresso_templatizer.gleam"],
    bundle: true,
    outfile: "./build/main.js",
    plugins: [esgleam({ main_function: "main", project_root: "." })],
  })
  .catch((e) => {
    console.log(e);
    process.exit(1);
  });
