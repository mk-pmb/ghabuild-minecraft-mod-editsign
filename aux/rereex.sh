#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function rereex () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly

  local T='build-gpl-up-to-v2.2.2'
  git checkout "$T" || return $?
  git reset --hard readme-official-downloads || return $?
  git chp origin/"$T"'~1' || return $?
  git branch --force reex || return $?
  git chp origin/"$T" || return $?
  git push --force origin "$T" || return $?

  local B="$(git branch --list | sed -nre 's~^\*? +(debug-|build-)~\1~p')"
  for B in $B; do
    [ "$B" == "$T" ] && continue
    git checkout "$B" || return $?
    git reset --hard reex || return $?
    git chp origin/"$B" || return $?
    git push --force origin "$B" || return $?
  done

  git checkout experimental || return $?
}










rereex "$@"; exit $?
