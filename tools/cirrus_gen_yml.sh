#!/usr/bin/env bash

set -euxo pipefail
shopt -s nullglob globstar

(
for CHANNEL in release; do
    OS=linux
    ARCH=x86_64

    # Pre-download tarballs and Git repos
    echo "${CHANNEL}_${OS}_${ARCH}_download_docker_builder:
  timeout_in: 120m
  out_${CHANNEL}_${OS}_${ARCH}_cache:
    folder: out
    fingerprint_script:
      - \"echo out_${CHANNEL}_${OS}_${ARCH}\"
    reupload_on_changes: true
    populate_script:
      - \"mkdir -p out\"
  git_${CHANNEL}_${OS}_${ARCH}_cache:
    folder: git_clones
    fingerprint_script:
      - \"echo git_${CHANNEL}_${OS}_${ARCH}\"
    reupload_on_changes: true
    populate_script:
      - \"mkdir -p git_clones\"
  build_script:
    - \"./tools/cirrus_build_project.sh ncdns ${CHANNEL} ${OS} ${ARCH} 0\""
    echo ""

    # TODO fine-tune this list
    for PROJECT in ncdns ncp11 ncprop279; do
        echo "${CHANNEL}_${OS}_${ARCH}_${PROJECT}_docker_builder:
  timeout_in: 120m
  out_${CHANNEL}_${OS}_${ARCH}_cache:
    folder: out
    fingerprint_script:
      - \"echo out_${CHANNEL}_${OS}_${ARCH}\"
    reupload_on_changes: true
    populate_script:
      - \"mkdir -p out\"
  git_${CHANNEL}_${OS}_${ARCH}_cache:
    folder: git_clones
    fingerprint_script:
      - \"echo git_${CHANNEL}_${OS}_${ARCH}\"
    reupload_on_changes: true
    populate_script:
      - \"mkdir -p git_clones\"
  build_script:
    - \"./tools/cirrus_build_project.sh ${PROJECT} ${CHANNEL} ${OS} ${ARCH} 1\""

        # Depend on previous project
        if [[ "$PROJECT" == "ncdns" ]]; then
            echo "  depends_on:
    - \"${CHANNEL}_${OS}_${ARCH}_download\""
        else
            echo "  depends_on:
    - \"${CHANNEL}_${OS}_${ARCH}_${PREV_PROJECT}\""
        fi

        PREV_PROJECT="$PROJECT"
        echo ""
    done
done
) > .cirrus.yml

# Timeout issues?
# Might want to increase the timeout -- but we're already using the 2 hour max.
# Might want to bump the CPU count -- but that's blocked by cirrus-ci-docs issue #741.
# Might want to split into smaller project sets.
# What is the CPU count limit?  "Linux Containers" docs say 8.0 CPU and 24 GB RAM; "FAQ" says 16.0 CPU.  docker_builder VM's are really 4.0 CPU and 15 GB RAM (12 GB of which is unused by the OS).