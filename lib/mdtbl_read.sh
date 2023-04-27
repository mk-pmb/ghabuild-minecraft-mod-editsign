#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function mdtbl_to_shvar () {
  sed -nrf <(echo '
    /^[| -]+$/b
    s~\t~ ~g
    s~\x27+~\x27\x22&\x22\x27~g
    s~ +\| +~\x27\t\x27~g;T
    s~^\| +~\x27~;T
    s~ +\|$~\x27~;T
    p
    ') -- "$@"
}


function mdtbl_for_each_row () {
  local T=() C=()
  readarray -t T < <(mdtbl_to_shvar)
  readarray -t C <<<"${T[0]//$'\t'/$'\n'}"
  T=( "${T[@]:1}" )
  local R=0 N="${#T[@]}" K= V=
  for V in "${T[@]}"; do
    (( R += 1 ))
    V=$'\t'"$V"
    for K in "${C[@]}"; do
      V="${V/$'\t'/" [$K]="}"
    done
    V="['#']=$R ['##']=$N ${V%%$'\t'*}"
    K= V= "$@" "$V" || return $?$(
      echo "E: $FUNCNAME: hook failed (rv=$?) for row $R/$N: '$*'" >&2)
  done
}












return 0
