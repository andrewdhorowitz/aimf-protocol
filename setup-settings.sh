#!/usr/bin/env bash
# setup-settings.sh — one-command standard pass for the PUBLIC AIMF
# repo (andrewdhorowitz/aimf-protocol), staged 2026-10-29 to bring the
# repo from the bare design to the repo-template kit standard. Adapted
# from the kit's v3.1 converger (the showcase pass is the other
# public-repo precedent). A converger, not an installer: every run
# compares the repo against the standard, applies only what is
# missing, and says so for the rest.
#
# Run it from the repo root, signed in as the repo owner (Termux or a
# GitHub Codespace, with the GitHub CLI `gh` installed + authenticated):
#   bash setup-settings.sh          — standard pass (all AIMF needs)
#   bash setup-settings.sh site     — also force-enable GitHub Pages
#                                     (not needed here: Pages is on)
# It is safe to re-run: every step checks the current state first and
# reports one of three outcomes —
#   ✓ applied now, or already correct (the line says which),
#   ✗ failed (the script carries on regardless),
#   – skipped, with the reason (plan gate, not applicable, ...).
#
# Why `site` is an argument, not a detection: at bootstrap time a
# brand-new repo contains only the template's files — there is no
# index.html to detect yet, even for a repo that will become a site a
# week later. So the owner passes the type in. Detection remains as the
# fallback for repos that already have their files: if Pages is already
# on, or an index.html sits at the root, the step fires without the
# argument. Pages can be enabled before any files exist; it just 404s
# until the first index.html lands.
#
# What it does:
#   1. Installs the staged workflows: EVERY *.yml file in ci-src/
#      (ci.yml, lighthouse.yml, links.yml) is copied into
#      .github/workflows/, skipping any file already present — existing
#      workflows are never overwritten. The workflows travel at ci-src/
#      because the Muse GitHub App cannot push files under
#      .github/workflows/; the repo owner can — see BOOTSTRAP-NOTES.md.
#   2. Applies the standard repo settings via `gh api`: Wiki off,
#      Projects off, GitHub Pages, Dependabot alerts on, Dependabot
#      security updates on, secret scanning + push protection, CodeQL
#      default setup, and the minimal "main-basics" ruleset (blocks
#      deletions + force pushes only; Repository admins always bypass;
#      NO required PRs or status checks — the owner's no-lockout
#      rule). Discussions is deliberately NOT touched: it varies per
#      project. If `gh` is missing or unauthenticated, this section is
#      skipped with one line; the file install + cleanup still happen.
#      Pages here is a READ, not a change: GitHub Pages is already on
#      (it serves the invite-page mirror), so the step reports it
#      already on — and it deliberately does NOT rewrite the repo
#      homepage. Since the 2026-10-29 move, the canonical home is
#      https://aimf.andrewdhorowitz.com/ and the github.io Pages is
#      the mirror; the homepage field belongs to the canonical
#      address, so this script leaves it exactly as it finds it.
#      CodeQL asks for javascript-typescript only (this repo has no
#      Python). Its JavaScript is inline in index.html, which GitHub
#      counts as HTML — on the showcase, GitHub refused default setup
#      for exactly that shape, so a fail line from this one step reads
#      as not-applicable, not as a problem; everything else still
#      applies.
#   3. Deletes itself (and ci-src/), and lands the removal and the
#      installed workflows in ONE cleanup commit, which it pushes.
#      The run's full output is captured to a temp file OUTSIDE the
#      repo first and only copied to setup-results.txt after the run
#      completes, so the commit can never race the log — and because
#      this repo is PUBLIC, setup-results.txt is a LOCAL file only:
#      deliberately left untracked, never committed (the showcase
#      variant's handling).
#
# Plan gates: this repo is public, so the free-plan gates that apply
# to private repos (secret scanning, CodeQL, rulesets, Pages needing
# GitHub Pro) do not apply here — every step is expected to run. The
# gate-detection helpers are kept from the kit version so a gated
# answer still reports as a skip (–) instead of a failure.
set -uo pipefail
cd "$(dirname "$0")"

# --- Arguments ---------------------------------------------------------
# One optional argument is understood: `site` (see header). Anything
# else is reported inside the run and otherwise ignored — a typo must
# never abort the bootstrap.
SITE_ARG=0
UNKNOWN_ARGS=""
for arg in "$@"; do
  case "$arg" in
    site) SITE_ARG=1 ;;
    *) UNKNOWN_ARGS="${UNKNOWN_ARGS:+$UNKNOWN_ARGS }$arg" ;;
  esac
done

RESULTS_FILE="setup-results.txt"
TMPLOG="$(mktemp)"

RESULTS=""
report() { # report <ok|already|fail|skip> <label>
  # ok and already both print ✓ — the label's wording carries which of
  # the two it was ("... on" vs "... already on").
  local mark="✓"
  [ "$1" = "fail" ] && mark="✗"
  [ "$1" = "skip" ] && mark="–"
  echo "$mark $2"
  RESULTS+="$mark $2"$'\n'
}
attempt() { # attempt <label> <command...>
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    report ok "$label"
  else
    report fail "$label (failed — continuing)"
  fi
}
is_plan_gated() { # is_plan_gated <captured api output>
  printf '%s' "$1" | grep -qiE 'upgrade to github pro|advanced security|make this repository public'
}
is_pages_gated() { # is_pages_gated <captured api output>
  printf '%s' "$1" | grep -qiE 'upgrade to github pro|make this repository public|does not support github pages|pages is not available'
}
attempt_sa() { # attempt_sa <label> <current status> <json body>
  # PATCHes one security_and_analysis feature at a time so secret
  # scanning and push protection report SEPARATE results. A current
  # status of "enabled" short-circuits to the already-correct line; a
  # plan-gate refusal is an expected skip, not a failure.
  local label="$1" current="$2" body="$3" out
  if [ "$current" = "enabled" ]; then
    report already "$label already on"
  elif out="$(gh api -X PATCH "repos/$OWNER/$REPO" --input - <<<"$body" 2>&1)"; then
    report ok "$label on"
  elif is_plan_gated "$out"; then
    report skip "$label — plan-gated on this repo (needs GitHub Pro here); skipped"
  else
    report fail "$label (failed — continuing)"
  fi
}
attempt_gated() { # attempt_gated <label> <command...>
  local label="$1"
  shift
  local out
  if out="$("$@" 2>&1)"; then
    report ok "$label"
  elif is_plan_gated "$out"; then
    report skip "$label — plan-gated on this repo (needs GitHub Pro here); skipped"
  else
    report fail "$label (failed — continuing)"
  fi
}
set_flag_off() { # set_flag_off <label> <current value> <json body>
  # For boolean repo features that should be OFF (Wiki, Projects): an
  # already-off flag is the already-correct outcome, not a PATCH.
  local label="$1" current="$2" body="$3"
  if [ "$current" = "false" ]; then
    report already "$label already off"
  else
    attempt "$label off" gh api -X PATCH "repos/$OWNER/$REPO" --input - <<<"$body"
  fi
}
attempt_toggle_on() { # attempt_toggle_on <label> <endpoint>
  # Dependabot toggles: the GET form of the endpoint answers 204 when
  # the feature is already on, 404 when it isn't — so read first, and
  # only PUT when it is actually missing.
  local label="$1" endpoint="$2"
  if gh api "$endpoint" >/dev/null 2>&1; then
    report already "$label already on"
  else
    attempt "$label on" gh api -X PUT "$endpoint"
  fi
}
enable_pages() { # enable_pages <reason the step fired>
  # POST the Pages config (main / root). An "already" refusal means the
  # state we wanted exists — that is the already-correct outcome, not
  # an error. A plan refusal on a private free-plan repo is an expected
  # skip. Returns non-zero when Pages did not end up enabled.
  local reason="$1" out
  if out="$(gh api -X POST "repos/$OWNER/$REPO/pages" --input - 2>&1 <<'JSON'
{"source": {"branch": "main", "path": "/"}}
JSON
  )"; then
    report ok "Pages enabled (main / root) — $reason"
  elif printf '%s' "$out" | grep -qi 'already'; then
    report already "Pages already on"
  elif is_pages_gated "$out"; then
    report skip "Pages — plan-gated on private repos (needs GitHub Pro); skipped"
    return 1
  else
    report fail "Pages enable (failed — continuing)"
    return 1
  fi
}
homepage_note() { # the homepage is NEVER rewritten by this variant
  # Since the 2026-10-29 move the canonical home is the custom domain
  # below and the github.io Pages address is a mirror. Whatever the
  # homepage field holds, this script leaves it exactly as found.
  report already "Homepage left as-is (canonical home is https://aimf.andrewdhorowitz.com/)"
}

main() {
echo "== File install =="
# Install EVERY staged workflow in ci-src/ into .github/workflows/,
# skipping (never overwriting) any file that's already there.
if [ -d ci-src ] && ls ci-src/*.yml >/dev/null 2>&1; then
  mkdir -p .github/workflows
  for staged in ci-src/*.yml; do
    base="$(basename "$staged")"
    if [ -f ".github/workflows/$base" ]; then
      report already "Workflow $base already installed (.github/workflows/$base) — left as-is"
    else
      cp "$staged" ".github/workflows/$base"
      report ok "Workflow installed (.github/workflows/$base)"
    fi
  done
else
  report skip "No staged workflows found (ci-src/*.yml) — nothing to install"
fi

echo ""
echo "== Repo settings (via gh api) =="

# Work out owner/repo from the git remote instead of hard-coding them.
REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
OWNER_REPO="$(printf '%s' "$REMOTE_URL" | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')"
OWNER="${OWNER_REPO%%/*}"
REPO="${OWNER_REPO##*/}"

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo "Skipped: the GitHub CLI (gh) is missing or not signed in here."
  echo "Settings can be done in the web UI instead; the file install above still stands."
  RESULTS+="– Repo settings skipped (gh unavailable)"$'\n'
elif [ "$OWNER" = "$OWNER_REPO" ] || [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  echo "Skipped: could not read owner/repo from the git remote ($REMOTE_URL)."
  RESULTS+="– Repo settings skipped (remote not parsed)"$'\n'
else
  echo "Repo: $OWNER/$REPO"
  if [ -n "$UNKNOWN_ARGS" ]; then
    report skip "Unrecognized argument(s) ignored: $UNKNOWN_ARGS (only 'site' is understood)"
  fi
  if [ "$SITE_ARG" = "1" ]; then
    echo "Mode: 'site' argument passed — Pages is wanted for this repo."
  fi

  # Read the current state once per field, so each step below can tell
  # "applied now" from "already correct" instead of patching blind.
  repo_field() { gh api "repos/$OWNER/$REPO" --jq "$1" 2>/dev/null || echo ""; }
  HAS_WIKI="$(repo_field '.has_wiki')"
  HAS_PROJECTS="$(repo_field '.has_projects')"
  VISIBILITY="$(repo_field '.visibility')"
  [ -z "$VISIBILITY" ] && VISIBILITY="unknown"
  SS_STATUS="$(repo_field '.security_and_analysis.secret_scanning.status // ""')"
  PP_STATUS="$(repo_field '.security_and_analysis.secret_scanning_push_protection.status // ""')"

  set_flag_off "Wiki feature" "$HAS_WIKI" '{"has_wiki": false}'

  set_flag_off "Projects feature" "$HAS_PROJECTS" '{"has_projects": false}'

  # GitHub Pages — option first, detection as fallback (see header).
  # The <owner>.github.io repo itself is the one special case: its
  # Pages address is the root, not a subpath.
  PAGES_URL="https://$OWNER.github.io/$REPO/"
  [ "$REPO" = "$OWNER.github.io" ] && PAGES_URL="https://$OWNER.github.io/"
  if gh api "repos/$OWNER/$REPO/pages" >/dev/null 2>&1; then
    report already "Pages already on ($PAGES_URL) — invite-page mirror; canonical home is https://aimf.andrewdhorowitz.com/"
    homepage_note
  elif [ "$SITE_ARG" = "1" ]; then
    if enable_pages "forced by the 'site' argument"; then
      homepage_note
    fi
  elif [ -f index.html ]; then
    if enable_pages "index.html at repo root — treating as a site repo"; then
      homepage_note
    fi
  else
    report skip "Pages — not a site repo (no index.html; pass 'site' to force)"
  fi

  attempt_toggle_on "Dependabot alerts" "repos/$OWNER/$REPO/vulnerability-alerts"

  attempt_toggle_on "Dependabot security updates" "repos/$OWNER/$REPO/automated-security-fixes"

  attempt_sa "Secret scanning" "$SS_STATUS" \
    '{"security_and_analysis": {"secret_scanning": {"status": "enabled"}}}'

  attempt_sa "Secret scanning push protection" "$PP_STATUS" \
    '{"security_and_analysis": {"secret_scanning_push_protection": {"status": "enabled"}}}'

  # CodeQL default setup: free on public repos, paid on private ones —
  # don't even call the API when the repo is private.
  if [ "$VISIBILITY" = "private" ]; then
    report skip "CodeQL default setup — skipped (paid on private repos)"
  else
    CQL_STATE="$(gh api "repos/$OWNER/$REPO/code-scanning/default-setup" --jq '.state' 2>/dev/null || echo "")"
    if [ "$CQL_STATE" = "configured" ]; then
      report already "CodeQL default setup already on"
    else
      attempt_gated "CodeQL default setup on" gh api -X PATCH "repos/$OWNER/$REPO/code-scanning/default-setup" --input - <<'JSON'
{"state": "configured", "languages": ["javascript-typescript"]}
JSON
    fi
  fi

  # Main ruleset — only create it if no ruleset already covers the
  # default branch. The GET response is checked for a plan-gate message
  # BEFORE anything tries to parse it as a list (a 403 error body is
  # what crashed the family-cards version of this step).
  if RULESETS_OUT="$(gh api "repos/$OWNER/$REPO/rulesets" 2>&1)"; then
    EXISTING="$(gh api "repos/$OWNER/$REPO/rulesets" --jq '[.[] | select(((.conditions.ref_name.include) // []) | index("~DEFAULT_BRANCH"))] | length' 2>/dev/null || echo error)"
    case "$EXISTING" in
      ''|*[!0-9]*)
        report fail "Main ruleset check unreadable — skipped creating (continuing)"
        ;;
      0)
        attempt "Main ruleset 'main-basics' created (blocks deletions + force pushes; repo admins always bypass)" gh api -X POST "repos/$OWNER/$REPO/rulesets" --input - <<'JSON'
{
  "name": "main-basics",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [
    {"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}
  ],
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "rules": [{"type": "deletion"}, {"type": "non_fast_forward"}]
}
JSON
        ;;
      *)
        report already "Main ruleset already exists — nothing to create"
        ;;
    esac
  elif is_plan_gated "$RULESETS_OUT"; then
    report skip "Main ruleset 'main-basics' — plan-gated on private repos (needs GitHub Pro); skipped"
  else
    report fail "Main ruleset check failed — skipped creating (continuing)"
  fi
fi

echo ""
echo "== Summary =="
printf '%s' "$RESULTS"
}

# Capture the whole run to a temp log OUTSIDE the repo first; only when
# it has fully finished is the log copied to setup-results.txt, so the
# results file always holds the complete, final output. (Local file
# only — never committed; see the header.)
main 2>&1 | tee "$TMPLOG"
cp "$TMPLOG" "$RESULTS_FILE"
rm -f "$TMPLOG"
echo ""
echo "Full output saved locally in $RESULTS_FILE (untracked — delete it whenever; it is NOT committed)."

echo ""
echo "== Cleanup =="
# One commit: this script removed, ci-src/ removed, and the installed
# workflows added. setup-results.txt is NOT part of it — it stays
# untracked in this clone. If the commit or push fails, the settings
# above still applied — tidy the files by hand.
git rm -q setup-settings.sh >/dev/null 2>&1 || rm -f setup-settings.sh
if [ -d ci-src ]; then
  git rm -rq ci-src >/dev/null 2>&1 || rm -rf ci-src
fi
[ -d .github/workflows ] && git add -- .github/workflows 2>/dev/null || true
git add -A -- setup-settings.sh ci-src 2>/dev/null || true
push_cleanup() { # plain push, retrying with an upstream if the branch has none
  git push -q 2>/dev/null || git push -q -u origin "$(git branch --show-current 2>/dev/null || echo main)"
}
if git diff --cached --quiet; then
  echo "Nothing staged — cleanup already done."
elif git commit -q -m "Standard pass: CI installed + repo settings applied (setup-settings.sh)" && push_cleanup; then
  echo "Cleanup committed and pushed — run output saved locally in setup-results.txt (not committed)."
else
  echo "NOTE: couldn't commit/push the cleanup. Everything above still applied;"
  echo "commit the removal of setup-settings.sh + ci-src/ by hand whenever convenient."
fi
