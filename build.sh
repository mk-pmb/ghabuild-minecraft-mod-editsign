#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function build_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?
  source -- lib/kisi.sh --lib || return $?
  build_"$@"
}


function build_sh () { "$@"; }


function build_inverse_rebase () {
  local BRAN="${1:-$INVERSE_REBASE_ONTO}"
  if [ -z "$BRAN" ]; then
    echo "D: $FUNCNAME: Branch not set. Skip."
    return 0
  fi
  git fetch --unshallow origin "$BRAN" || return $?
  git branch --force {,origin/}"$BRAN" || return $?
  local SELF="$(basename -- "$BASH_SOURCE")"
  git checkout -b rebased || return $?
  git checkout "$BRAN" -- "$SELF" lib/ || return $?
  ./"$SELF" "${FUNCNAME#*_}_stage2" "$@" || return $?
}


function build_clone_mod_repo () {
  local GIT_ARGS=(
    clone
    --no-recurse-submodules
    --depth=1
    "$@"
    https://github.com/Rakambda/EditSign.git
    mod-repo
    )
  git "${GIT_ARGS[@]}" || return $?
}


function build_generate_matrix () {
  sed -nre 's~^(\s*)([a-z][^: ]*):~  \1"\2":~p' -- ci.cfg | sed -rf <(echo '
    $!s~$~,~
    1s~^ ~opt={~
    $s~$~\n}~
    ') >>"$GITHUB_OUTPUT" || return $?

  echo 'mx={"b":[{"#": "placeholder"}]}' >>"$GITHUB_OUTPUT" || return $?
}


function build_summarize_step_env_vars () {
  local TITLE= TEXT= FMT=
  for TEXT in "$@"; do
    eval 'TEXT="$'"$TEXT"'"'
    [ -n "$TEXT" ] || continue
    TITLE="${TEXT%% <*}"; TEXT="${TEXT#* <}"
    FMT="${TEXT%%> *}"; TEXT="${TEXT#*> }"
    fmt_markdown_details_file "$TITLE" "${FMT:-text}" <<<"$TEXT" \
      >>"$GITHUB_STEP_SUMMARY" || return $?
  done
}


function build_shellify_build_matrix_entry () {
  echo "$JSON" >tmp.matrix_entry.json
}


function build_apply_hotfixes () {
  echo 'Stub!'
}









build_init "$@"; exit $?
