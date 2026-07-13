#!/usr/bin/env bash
# aish_enterprise :: on_init lifecycle hook
# ------------------------------------------------------------------------------
# Runs once when the plugin is loaded, BEFORE the shell is interactive (design
# lifecycle: on_init). Its job is the "login handshake + pull managed config"
# that 04-client-integration.md calls the Phase-0 unlock:
#
#   1. Resolve the tenant credential (from `aish login` / device-code, stored in
#      ~/.aish/credentials profile [aish_enterprise]).
#   2. Export the env the injected .mcp.json + hooks.json + skill provider read.
#   3. Pull the org's managed config (skill allow-list, MCP-gateway URL, policy
#      bundle, model defaults) and stage it for the client to merge.
#
# Contract: emit `KEY=VALUE` lines on stdout — the plugin loader adds them to the
# session environment (design `provides.config` / env-injection capability, see
# the OSS PLUGIN_SYSTEM_DESIGN enterprise addendum). Never print secret VALUES to
# logs; only names. Exit non-zero ONLY on a fatal misconfig — a transient control
# -plane outage must fail OPEN so the OSS shell still starts.
set -euo pipefail

CONF_DIR="${AISH_PLUGIN_CONFIG_DIR:-$HOME/.aish/plugins/aish_enterprise}"
CRED_FILE="$HOME/.aish/credentials"
GATEWAY_URL="${AISH_ENTERPRISE_GATEWAY_URL:-https://gateway.aish.sh}"
REGISTRY_URL="${AISH_ENTERPRISE_SKILL_REGISTRY_URL:-https://registry.aish.sh}"
CONTROL_URL="${AISH_ENTERPRISE_CONTROL_URL:-https://api.aish.sh}"

# --- 1. resolve tenant binding (written by `aish login`) ----------------------
TENANT="$(git config --file "$CRED_FILE" --get aish_enterprise.tenant 2>/dev/null || true)"
if [ -z "${TENANT}" ]; then
  # Not logged in yet: fail OPEN. The `aish_login` tool prompts the user.
  echo "AISH_ENTERPRISE_STATUS=unauthenticated" 
  exit 0
fi

# --- 2. export env the injected config templates consume ----------------------
echo "AISH_ENTERPRISE_TENANT=${TENANT}"
echo "AISH_ENTERPRISE_GATEWAY_URL=${GATEWAY_URL}"
# Point the OSS skill provider at the org registry (src/skill_provider.rs reads
# AISH_SKILL_REGISTRY). This is the managed-skills seam — Pillars C & E.
echo "AISH_SKILL_REGISTRY=${REGISTRY_URL}"

# --- 3. pull managed config (best-effort; fail open) --------------------------
# Stages the org-managed hooks.json/policy bundle for the client to merge at
# SessionStart. Auth is the tenant key; nothing here echoes the key value.
if command -v curl >/dev/null 2>&1; then
  curl --fail --silent --show-error --max-time 5 \
    -H "Authorization: Bearer ${AISH_ENTERPRISE_API_KEY:-}" \
    "${CONTROL_URL}/v1/tenants/${TENANT}/managed-config" \
    -o "${CONF_DIR}/managed.json" 2>/dev/null \
    && echo "AISH_ENTERPRISE_MANAGED_CONFIG=${CONF_DIR}/managed.json" \
    || echo "AISH_ENTERPRISE_STATUS=degraded(control-plane-unreachable)"
fi

echo "AISH_ENTERPRISE_STATUS=ready"
exit 0
