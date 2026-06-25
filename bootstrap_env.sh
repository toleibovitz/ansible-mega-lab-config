#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "================================================================="
echo " Starting Ansible Mega-Lab Controller Bootstrap Script (Python 3.12)"
echo "================================================================="

# 1. Ensure the script is run with sudo privileges (needed for DNF steps)
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: Please run this script with sudo or as root."
  echo "    Command: sudo ./bootstrap_env.sh"
  exit 1
fi

# 2. Get the current logged-in user who called sudo
# (We need this to ensure the venv belongs to your standard student user, not root)
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo "~$REAL_USER")
REPO_DIR=$(pwd)

echo "[+] Operating inside repo: ${REPO_DIR}"
echo "[+] Target environment owner: ${REAL_USER}"

# 3. Detect RHEL version and install Python 3.12 + Development Tooling
RHEL_VERSION=$(rpm -E %rhel)
echo "[+] Detected OS: RHEL ${RHEL_VERSION}"

echo "[+] Updating package metadata and installing Python 3.12..."
dnf clean all
dnf install -y python3.12 python3.12-devel gcc openssh-clients git sshpass iputils bind-utils

# 4. Check for project requirement configuration files
if [ ! -f "requirements.txt" ] || [ ! -f "requirements.yml" ]; then
    echo "[-] Error: requirements.txt or requirements.yml missing from ${REPO_DIR}."
    exit 1
fi

# 5. Build/Rebuild the Virtual Environment under Python 3.12
echo "[+] Blowing away old virtual environment (if any)..."
rm -rf "${REPO_DIR}/venv"

echo "[+] Building fresh virtual environment explicitly using Python 3.12..."
sudo -u "${REAL_USER}" python3.12 -m venv "${REPO_DIR}/venv"

# 6. Install Python and Ansible requirements inside the Venv context
echo "[+] Upgrading core pip components and installing requirements..."
sudo -u "${REAL_USER}" bash -c "
    source ${REPO_DIR}/venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r ${REPO_DIR}/requirements.txt
    ansible-galaxy collection install -r ${REPO_DIR}/requirements.yml --upgrade
"

# 7. Set correct permissions on the newly created venv folder structure
chown -R "${REAL_USER}:${REAL_USER}" "${REPO_DIR}/venv"

echo "================================================================="
echo "[+] SUCCESS: Environment initialized successfully!"
echo "================================================================="
echo " To activate your new environment and start automating, run:"
echo "      source venv/bin/activate"
echo "================================================================="