#!/bin/bash
set -e

#
# Builds the rustdocs for all of the libraries.
#

# Brings in: PROJECT_ROOT, EXAMPLES_DIR, LIB_DIR, CODEGEN_DIR, CONTRIB_DIR, DOC_DIR
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/config.sh"

if [ "${1}" != "-d" ]; then
  # We need to clean-up beforehand so we don't get all of the dependencies.
  echo ":::: Cleaning up before documenting..."
  cargo clean
  cargo update
fi

# Generate the rustdocs for all of the crates.
echo ":::: Generating docs (${DOC_VERSION})..."
pushd "${PROJECT_ROOT}" > /dev/null 2>&1
  # Set the crate version and fill in missing doc URLs with docs.rs links.
  RUSTDOCFLAGS="-Z unstable-options \
      --crate-version ${DOC_VERSION} \
      --generate-link-to-definition" \
      cargo doc -Zrustdoc-map --no-deps --all-features \
        -p rocket \
        -p rocket_db_pools \
        -p rocket_sync_db_pools \
        -p rocket_dyn_templates \
        -p rocket_ws
popd > /dev/null 2>&1

# Generating redirection list: from    to.
echo ":::: Generating redirects..."
REDIRECTS="
/               /v0.5/rocket/                                302!
/v0.4           https://docs.rs/rocket/0.4/rocket/
/v0.4/:crate/*  https://docs.rs/:crate/0.4/:crate/:splat
/:v             /:v/rocket/
/v0.5/*         https://v0-5--rocket-docs.netlify.app/:splat 200
/:v/*           https://:v--rocket-docs.netlify.app/:splat   200
"

if [ "${GIT_BRANCH}" = "master" ]; then
  echo "${REDIRECTS}" | tee "${DOC_DIR}/_redirects"
else
  echo "-> '${GIT_BRANCH}' branch does not require redirects"
fi
