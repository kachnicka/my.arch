#!/usr/bin/env bash
# handy-route.sh — receive Handy dictation transcript as $1, route by mode.
# Called by Handy when Paste Method = external_script.
# NOTE: mutually exclusive with handy-ptt (which needs paste_method =
# ctrl_shift_v) — only one of the two can be active in Handy at a time.
#
# Mode selection (in priority order):
#   1. First-word token in the transcript: "inbox ...", "tmux ...", "spec ..."
#      (voice-native: say the target first; token is stripped from output)
#   2. HANDY_ROUTE env var (set in Handy's launch environment)
#   3. Default: inbox
#
# Modes:
#   inbox  append timestamped to ~/notes/voice-inbox.md
#   tmux   insert text into an OpenCode tmux pane (matched by command name)
#   spec   append into active OpenSpec change (requires HANDY_SPEC_ROOT env
#          pointing at the project root; falls back to inbox with notice)
#
# Configure in Handy: Settings > Paste Method > External Script,
# path = ~/.local/bin/handy-route.sh

set -euo pipefail

TRANSCRIPT="${1:-}"
[ -n "$TRANSCRIPT" ] || exit 0
MODE="${HANDY_ROUTE:-inbox}"
case "$TRANSCRIPT" in
  inbox\ *|tmux\ *|spec\ *) MODE="${TRANSCRIPT%% *}"; TRANSCRIPT="${TRANSCRIPT#* }" ;;
esac

SHORT="$(printf '%s' "$TRANSCRIPT" | head -c 60)"
inbox() {
  mkdir -p "$HOME/notes"
  printf '\n## %s\n\n%s\n' "$(date -Iseconds)" "$TRANSCRIPT" >> "$HOME/notes/voice-inbox.md"
  notify-send "Handy" "Transcript → notes/voice-inbox.md" 2>/dev/null || true
}
fallback_inbox() {
  # arg 1: what failed
  mkdir -p "$HOME/notes"
  printf '\n## %s\n\n%s\n' "$(date -Iseconds)" "$TRANSCRIPT" >> "$HOME/notes/voice-inbox.md"
  notify-send "Handy" "$1 — transcript → notes/voice-inbox.md" 2>/dev/null || true
}

case "$MODE" in
  inbox)
    inbox
    ;;
  tmux)
    # Target first pane whose running command is 'opencode'; never inject
    # into an arbitrary pane. NB: foreground-name matching breaks if
    # opencode is launched via a wrapper script — route falls back to
    # clipboard with a notification.
    PANE="$(tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null | awk '$2=="opencode"{print $1; exit}' || true)"
    if [ -n "${PANE:-}" ]; then
      # load-buffer + paste-buffer -p (bracketed paste) so newlines in the
      # transcript don't submit partial input line-by-line.
      printf '%s' "$TRANSCRIPT" | tmux load-buffer -b handy-transcript - && \
        tmux paste-buffer -b handy-transcript -t "$PANE" -p
      notify-send "Handy" "Transcript → tmux opencode pane: $SHORT" 2>/dev/null || true
    elif command -v wl-copy >/dev/null 2>&1; then
      printf '%s' "$TRANSCRIPT" | wl-copy
      notify-send "Handy" "No opencode pane — transcript → clipboard" 2>/dev/null || true
    else
      fallback_inbox "No opencode pane, no wl-copy"
    fi
    ;;
  spec)
    # Append into active OpenSpec change. NB: "active" = most recently
    # modified change dir — touching another change (generator, editor
    # autosave) redirects dictations there; notification shows the target.
    if [ -n "${HANDY_SPEC_ROOT:-}" ] && CHANGE_DIR="$(ls -dt "$HANDY_SPEC_ROOT"/openspec/changes/*/ 2>/dev/null | head -1 || true)" && [ -n "${CHANGE_DIR:-}" ]; then
      printf '\n%s\n' "$TRANSCRIPT" >> "${CHANGE_DIR}proposal.md"
      notify-send "Handy" "Transcript → ${CHANGE_DIR}proposal.md" 2>/dev/null || true
    else
      fallback_inbox "spec mode: HANDY_SPEC_ROOT unset or no active change"
    fi
    ;;
  *)
    printf 'handy-route: unknown mode %s\n' "$MODE" >&2
    fallback_inbox "unknown mode '$MODE'"
    ;;
esac
