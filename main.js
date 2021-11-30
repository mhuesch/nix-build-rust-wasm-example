import init, { run_app } from './app.js';
async function main() {
   await init('./nix_build_rust_wasm_example.wasm');
   run_app();
}
main()
