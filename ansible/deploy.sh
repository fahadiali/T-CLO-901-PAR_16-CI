#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"ssh -i ~/.ssh/id_rsa user@host\"" >&2
  exit 1
fi

SSH_CMD="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_PATH="${REPO_ROOT}/sample-app-master"
REMOTE_PATH="${REMOTE_PATH:-/opt/sample-app}"

read -r -a TOKENS <<< "${SSH_CMD}"
if [[ ${#TOKENS[@]} -lt 2 ]]; then
  echo "Provided SSH command looks invalid." >&2
  exit 1
fi

SSH_USER=""
SSH_HOST=""
SSH_PORT=""
SSH_KEY=""

for ((i=0; i<${#TOKENS[@]}; i++)); do
  token="${TOKENS[$i]}"
  case "${token}" in
    -i)
      if (( i + 1 < ${#TOKENS[@]} )); then
        SSH_KEY="${TOKENS[$((i+1))]}"
        if [[ ${SSH_KEY} == ~* ]]; then
          SSH_KEY="${SSH_KEY/#\~/${HOME}}"
        fi
      fi
      ((i++))
      ;;
    -p)
      if (( i + 1 < ${#TOKENS[@]} )); then
        SSH_PORT="${TOKENS[$((i+1))]}"
      fi
      ((i++))
      ;;
    *@*)
      SSH_USER="${token%@*}"
      SSH_HOST="${token#*@}"
      ;;
    *)
      continue
      ;;
  esac
done

if [[ -z "${SSH_USER}" || -z "${SSH_HOST}" ]]; then
  echo "Unable to detect user@host in the SSH command." >&2
  exit 1
fi

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Project directory not found at ${PROJECT_PATH}" >&2
  exit 1
fi

INVENTORY_FILE="$(mktemp)"
trap 'rm -f "${INVENTORY_FILE}"' EXIT

echo "[target]" > "${INVENTORY_FILE}"
printf "vm ansible_host=%s ansible_user=%s" "${SSH_HOST}" "${SSH_USER}" >> "${INVENTORY_FILE}"
if [[ -n "${SSH_KEY}" ]]; then
  printf " ansible_ssh_private_key_file=%s" "${SSH_KEY}" >> "${INVENTORY_FILE}"
fi
if [[ -n "${SSH_PORT}" ]]; then
  printf " ansible_port=%s" "${SSH_PORT}" >> "${INVENTORY_FILE}"
fi
printf '\n' >> "${INVENTORY_FILE}"

export ANSIBLE_CONFIG="${SCRIPT_DIR}/ansible.cfg"
ansible-playbook -i "${INVENTORY_FILE}" "${SCRIPT_DIR}/deploy.yml" \
  -e "local_project_path=${PROJECT_PATH}" -e "remote_project_path=${REMOTE_PATH}"
