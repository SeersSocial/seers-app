#!/bin/bash
#
# additional setup, e.g., build frontend assets:
# ...
# Rust build:
export RUSTFLAGS="--remap-path-prefix $(readlink -f $(dirname ${0}))=/build --remap-path-prefix ${CARGO_HOME}=/cargo"
cargo build --locked --target wasm32-unknown-unknown --release
ic-wasm target/wasm32-unknown-unknown/release/example_backend.wasm -o example_backend.wasm shrink