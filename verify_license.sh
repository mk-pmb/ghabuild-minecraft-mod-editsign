#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function verify_license () {
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?

  local LICENSE_FILES="$( find mod-repo/ -type f -iname '*license*' )"
  LICENSE_FILES="${LICENSE_FILES//$'\n'/ }"
  case "$LICENSE_FILES" in
    'mod-repo/LICENSE.md' ) ;;
    * ) echo "E: Unexpected license file(s): '$LICENSE_FILES'" >&2; return 2;;
  esac

  local SHA=
  case "$EXPECTED_LICENSE" in
    'GPL-3.0-only' ) SHA='7bc5474bacf20ef085e04ded37c5e604c197cf07';;
    'LGPL-3.0-only' ) SHA='a8a12e6867d7ee39c21d9b11a984066099b6fb6b';;
    * ) echo "E: Unknown license name: '$EXPECTED_LICENSE'" >&2; return 2;;
  esac

  local OUT='jar-unpacked'
  mkdir --parents -- "$OUT" || return $?
  cp --target-directory="$OUT" --verbose \
    -- LICENSE.mojang_taint.txt || return $?
  OUT+="/LICENSE.$EXPECTED_LICENSE.txt"
  cp --verbose --no-target-directory -- "$LICENSE_FILES" "$OUT" || return $?
  sha1sum --check - <<<"$SHA *$OUT" || return $?
}


verify_license "$@"; exit $?
