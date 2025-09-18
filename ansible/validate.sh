#!/bin/bash

set -e

echo " Checking and converting files to Unix line endings if needed..."
find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.ini" \) -print0 | while IFS= read -r -d '' file; do
  if grep -q $'\r' "$file"; then
    echo " Converting $file to Unix format..."
    dos2unix "$file"
  fi
done
echo " All YAML/INI files are now in Unix format."


echo ""
echo " Running yamllint on all YAML files..."
if ! yamllint -f parsable setup.yml roles/ ; then
  echo " yamllint failed!"
  exit 1
fi
echo " yamllint successful."


echo ""
echo " Checking for ansible-lint..."
if ! command -v ansible-lint &> /dev/null; then
    echo " ansible-lint: command not found"
    echo " To install ansible-lint in your WSL environment, run:"
    echo "    pipx install ansible-lint"
    exit 1
fi
echo " ansible-lint found. Running lint check..."

if ! ansible-lint setup.yml roles/*/tasks/*.yml ; then
  echo " ansible-lint failed!"
  exit 1
fi
echo " ansible-lint successful."


echo ""
echo " Checking for ansible-playbook..."
if ! command ansible-playbook &> /dev/null; then
    echo " ansible-playbook: command not found"
    echo " To install it, run: pipx install ansible"
    exit 1
fi
echo " ansible-playbook found. Running dry-run..."

if ! ansible-playbook setup.yml -i hosts.ini --check --diff ; then
  echo "Dry-run failed!"
  exit 1
fi
echo " Dry-run successful."

echo ""
echo " Validation complete. All checks passed."
