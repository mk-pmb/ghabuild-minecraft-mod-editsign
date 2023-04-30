#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function record_successful_builds () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local GHA_PATH="$(readlink -m -- "$BASH_SOURCE"/../..)"
  source -- "$GHA_PATH"/lib/json.sh --lib || return $?
  source -- "$GHA_PATH"/lib/parse_mod_tag.sh --lib || return $?

  cd -- "${1:-.}" || return $?
  shift

  local JARZIP=
  for JARZIP in *.jar.zip; do
    report_one_jarzip
  done
}


function report_one_jarzip () {
  printf '%- 40s' "${JARZIP%.zip}"
  local -A M=()
  M=()
  eval "M=( $(unzip -p -- "$JARZIP" META-INF/build_matrix_entry.json \
    | naive_json_to_shell_dict) )"
  parse_mod_tag || return $?
  printf '%- 24s' "${M[modver]}:${M[mcr]}:${M[loader]}"
  echo "${M[tag]}"
}










record_successful_builds "$@"; exit $?
