#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function build_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?
  source -- lib/json.sh --lib || return $?
  source -- lib/kisi.sh --lib || return $?
  source -- lib/mdtbl_read.sh --lib || return $?

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


function build_inverse_rebase_stage2 () {
  local BRAN="${1:-$INVERSE_REBASE_ONTO}"
  echo "--- Inverse rebase stage 2 -> '$BRAN' ---"
  vdo git branch --verbose || return $?
  local ORIG="$(git rev-parse HEAD)"
  vdo git log --oneline "$BRAN" || return $?
  vdo git log --oneline "$ORIG" || return $?

  local TREE='git log --oneline --graph --decorate --all'
  vdo $TREE || return $?
  vdo git reset --hard "$BRAN" || return $?

  # Identity is required before we can rebase:
  git config --global user.name   'CI'
  git config --global user.email  'ci@example.net'
  vdo git rebase -- "${ORIG:0:7}" || return $?

  vdo $TREE || return $?
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

  local M="$(<matrix.md mdtbl_for_each_row build_fmt_matrix_line)"
  [ -n "$M" ] || M='[ { "": "placeholder" } ]'
  local J='tmp.matrix.json'
  <<<"$M" vdo tee -- "$J" || return $?
  <<<'mx={ "b": '"${M//$'\n'/ }"' }' vdo tee --append \
    -- "$GITHUB_OUTPUT" || return $?
}


function build_fmt_matrix_line () {
  local -A M=()
  eval "M=( $1 )"
  [ "${M[#]}" == 1 ] && echo '['

  local T="${M[tag]}"
  M[modref]="refs/tags/$T"

  local L=
  case "${M[tag]}" in
    EditSign-[A-Z]*-[0-9]* )
      L="${M[tag],,}"
      L="${L#*-}"
      L="${L%%-*}"
      ;;
  esac
  local A="editsign-v${M[modver]}-mc${M[mcr]}-$L"
  A="${A%-}.jar"
  M[artifact]="$A"

  naive_jsonify_oneline M '{' ' }' \
    modver mcr license java tag modref artifact || return $?
  if [ "${M[#]}" == "${M[##]}" ]; then
    echo
    echo ']'
  else
    echo ','
  fi
}


function build_summarize_step_env_vars () {
  local TITLE= TEXT= FMT=
  for TEXT in "$@"; do
    eval 'TEXT="$'"$TEXT"'"'
    [ -n "$TEXT" ] || continue
    TITLE="${TEXT%% <*}"; TEXT="${TEXT#* <}"
    FMT="${TEXT%%> *}"; TEXT="${TEXT#*> }"
    ghstep_dump_file "$TITLE" "${FMT:-text}" <<<"$TEXT" || return $?
  done
}


function build_shellify_build_matrix_entry () {
  echo "$JSON" >tmp.matrix_entry.json
  <<<"$JSON" naive_json_to_shell_dict | tee -- tmp.matrix_entry.dict \
    | ghstep_dump_file "Build matrix entry as bash dict" bash || return $?
}


function build_apply_hotfixes () {
  echo 'Stub!'
}









build_init "$@"; exit $?
