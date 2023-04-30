#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
#
# This file is dual-licensed, see README.md.


function fixes_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local GHA_DIR="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$GHA_DIR" || return $?
  source -- lib/kisi.sh --lib || return $?

  local -A CFG=()
  local INJ='hotfix.inject.sh'
  [ ! -f "$INJ" ] || vdo source -- "$INJ" || return $?$(
    echo "E: Injection of extra-hot hotfixes failed, rv=$?" >&2)

  local TASK="$1"; shift
  fixes_"${TASK:-apply}" "$@"; return $?
}


function fixes_decide () {
  local -A M=()
  eval "M=( $1 )"
  local FIXES=

  decide_group1 || return $?

  echo ${CFG[inj_todo_early]} $FIXES ${CFG[inj_todo_late]}
}


function decide_group1 () {
  # case "${M[modver]}:${M[mcr]}:${M[loader]}" in
  case "${M[tag]}" in
    . ) FIXES+=' #confirmed:230501'; return 0;;
  esac

  FIXES+=' #unverified'
}


function fixes_apply () {
  [ -d mod-repo ] || return 0$(
    echo 'W: No mod-repo present to be hotfixed.' >&2)
  local -A M=()
  eval "M=( $(cat -- tmp.matrix_entry.dict) )"

  local FIXES_TODO="$*"
  [ "$FIXES_TODO" == --from-matrix ] && FIXES_TODO="${M[hotfixes]}"

  cd -- mod-repo || return $?
  git checkout -b hotfixed || return $?

  local AUX_META_DIR="$GHA_DIR/jar-unpacked/META-INF"
  local HOTFIX_PATCH_LOG="$AUX_META_DIR/hotfixes.log"
  >"$HOTFIX_PATCH_LOG" || return $?
  fixes_multi "$FIXES_TODO" || return $?
}


function fixes_multi () {
  local FUNC= DESCR= AFFECTED=
  local {APPLIED,USELESS}_{F,N}=
  for FUNC in $*; do
    [ "${FUNC:0:1}" == '#' ] && continue
    DESCR="${FUNC//_/ }"
    FUNC="${FUNC,,}"
    FUNC="${FUNC#fix_}"
    FUNC="${FUNC//[.-]/_}"
    echo "---- $DESCR: ----"
    fix_"$FUNC" || return $?$(echo "E: Failed to apply fix $DESCR, rv=$?" >&2)
    AFFECTED="$(git status --short)"
    AFFECTED="${AFFECTED//$'\n'/, }"
    if [ -n "$AFFECTED" ]; then
      echo "$AFFECTED"
      APPLIED_F+=" `$FUNC`"
      (( APPLIED_N += 1 ))
      git add --all --no-ignore-removal . || return $?
      git commit -m "[hotfix] $DESCR" || return $?
      git show --irreversible-delete HEAD >>"$HOTFIX_PATCH_LOG" || return $?
    else
      echo '(no files affected.)'
      USELESS_F+=" `$FUNC`"
      (( USELESS_N += 1 ))
    fi
  done

  echo '---- Summary ----'
  echo >>"$GITHUB_STEP_SUMMARY"
  ( echo "* patches applied: $APPLIED_F ($APPLIED_N)"
    echo "* useless patches: $USELESS_F ($USELESS_N)"
  ) | tee --append -- "$GITHUB_STEP_SUMMARY"
  echo >>"$GITHUB_STEP_SUMMARY"
}












fixes_main "$@"; exit $?
