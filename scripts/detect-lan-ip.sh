#!/usr/bin/env bash
# Prints the PC's LAN/Wi-Fi IP for physical phones (excludes Docker, virbr0, loopback).
set -euo pipefail

is_excluded_ip() {
  local ip="$1"
  case "$ip" in
    127.*) return 0 ;;
    172.1[789].*|172.2[0-9].*) return 0 ;;
    192.168.122.*) return 0 ;; # libvirt virbr0 — not your Wi-Fi
    10.0.2.*) return 0 ;;
  esac
  return 1
}

pick_lan_ip() {
  local ip="" cand

  if command -v ip >/dev/null 2>&1; then
    ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/\bsrc\b/ { print $7; exit }' || true)
    if [[ -n "$ip" ]] && is_excluded_ip "$ip"; then
      ip=""
    fi
  fi

  if [[ -z "$ip" ]] && command -v hostname >/dev/null 2>&1; then
    for cand in $(hostname -I 2>/dev/null); do
      if is_excluded_ip "$cand"; then
        continue
      fi
      case "$cand" in
        10.*|192.168.*)
          ip="$cand"
          break
          ;;
      esac
    done
  fi

  echo "$ip"
}

pick_lan_ip
