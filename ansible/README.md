# Ansible (GitHub Actions self-hosted runners)

Provisions the official [actions/runner](https://github.com/actions/runner) on **macOS or Linux** using the Galaxy role **[monolithprojects.github_actions_runner](https://github.com/MonolithProjects/ansible-github_actions_runner)** (MonolithProjects), plus **Ballai-only** extras on macOS (Homebrew **gnu-tar** for `ansible.builtin.unarchive`, and **swiftlint** / **xcodegen** / **xcbeautify**).

Default registration: repository **`spooky-fox/ballai`** with label **`ballai-ci`**, install dir **`$HOME/actions-runner`**.

## One-time setup

1. **Toolchain:** `brew install uv` (on the controller), then `cd ansible && uv sync`
2. **Install Galaxy dependencies** (roles + collections):

   ```bash
   cd ansible
   uv run ansible-galaxy role install -r requirements.yml
   uv run ansible-galaxy collection install -r collections/requirements.yml
   ```

   - Roles → **`ansible/.ansible/roles/`** (gitignored).
   - Collections ( **`amazon.aws`** for optional Secrets Manager lookup) → **`ansible/.ansible/collections/`** (gitignored).

3. **GitHub PAT on the controller** (the machine running Ansible), one of:
   - **`ansible/github_token`** — single line (`ghp_...` or fine-grained token with repo access to manage runners). **`chmod 600`**. (Gitignored.)
   - Or omit the file and set **`GITHUB_TOKEN`** or **`PERSONAL_ACCESS_TOKEN`** in the environment (Monolith’s usual name is `PERSONAL_ACCESS_TOKEN`; this playbook accepts either).

4. **Sudo / become:** The Monolith role uses **`become: true`** to create `runner_dir`, unpack the tarball, and run `config.sh` as `runner_user`. On macOS, **`./svc.sh install` / `start`** still run **without** become (LaunchAgent).

   Password resolution order (first hit wins):

   1. **`github_actions_runner_become_password_file`** if you set it (path must exist).
   2. **`ansible/.pw`** — single line, **`chmod 600`** (gitignored). See **`pw.example`**.
   3. **`ansible/become_password`** — legacy filename, same format.
   4. Environment **`ANSIBLE_BECOME_PASSWORD`**.
   5. **AWS Secrets Manager** if **`BALLAI_ANSIBLE_BECOME_SECRET_ID`** is set (secret **name or ARN**; use a **plain string** secret for direct lookup, or run **`sync_ansible_secrets_from_aws.sh`** to materialize **`.pw`** from a JSON secret). Requires **`amazon.aws`** collection installed.

   **Automation (AWS → local file):** from repo root, with **`BALLAI_ANSIBLE_BECOME_SECRET_ID`** set and AWS credentials loaded (e.g. **`set -a && source .env && set +a`**, then **`unset AWS_PROFILE AWS_CONFIG_FILE AWS_SHARED_CREDENTIALS_FILE`** per team conventions):

   ```bash
   cd ansible && ./scripts/sync_ansible_secrets_from_aws.sh
   ```

   Optional: secret value is JSON — set **`BALLAI_ANSIBLE_BECOME_SECRET_JSON_KEY`** to the field name (e.g. `password`) before running the script.

   You can also use **`ansible-playbook --become-password-file=...`** or **`--ask-become-pass`**.

5. **Run:**

   ```bash
   cd ansible
   uv run ansible-playbook -i inventory playbooks/github_actions_runner.yml
   ```

   **`playbooks/github_actions_runner_mac.yml`** only **`import_playbook`**’s the file above (backward-compatible path).

Copy examples: `cp github_token.example github_token` then replace the token; **`chmod 600 github_token`**.

**Inventory note:** The play targets **`github_runners:mac_runners`**. **`inventory.example`** includes an **empty `[mac_runners]`** group so Ansible does not warn about an unknown pattern. Add hosts there only if you use the legacy layout.

### Inventory warning: **`ignoring: mac_runners`**

If you see it, add an empty **`[mac_runners]`** group (see **`inventory.example`**).

The Monolith runner role is **vendored** under **`roles/monolithprojects.github_actions_runner/`** with ansible-core 2.20+ fixes (see **`roles/README.md`**).

## Secrets Management

Secrets can be provided through **Ansible Vault**, **plaintext files**, **environment variables**, or **AWS Secrets Manager**. The playbook resolves each secret using the first source that provides a value.

### Ansible Vault (recommended for shared / versioned secrets)

1. **Vault password file:** `cp .vault-password-file.example .vault-password-file`, replace the placeholder with your vault password, then `chmod 600 .vault-password-file`. `ansible.cfg` auto-loads it. In CI, write the password from a pipeline secret:

   ```bash
   echo "$VAULT_PASSWORD" > .vault-password-file
   ```

   Alternatively, set **`ANSIBLE_VAULT_PASSWORD_FILE`** to point at any file containing the password.

2. **Encrypted variables:** `cp group_vars/all/vault.yml.example group_vars/all/vault.yml`, fill in real values, then encrypt:

   ```bash
   ansible-vault encrypt group_vars/all/vault.yml
   ```

   Variables defined there (e.g. `vault_github_token`, `vault_become_password`) are automatically loaded for every play targeting the `all` group.

### Resolution order

| Secret | Priority (first wins) |
|--------|----------------------|
| **GitHub PAT** | vault `vault_github_token` → `ansible/github_token` file → `GITHUB_TOKEN` / `PERSONAL_ACCESS_TOKEN` env |
| **Become password** | vault `vault_become_password` → override file → `ansible/.pw` → `ansible/become_password` → `ANSIBLE_BECOME_PASSWORD` env → AWS Secrets Manager |

Plaintext files (`github_token`, `.pw`, `become_password`) and the sync script (`scripts/sync_ansible_secrets_from_aws.sh`) still work exactly as before — vault is an additive layer.

## Requirements

- **Python 3.12+** and **ansible-core 2.20+** (see `pyproject.toml`). The play asserts Ansible’s version at runtime.
- **uv** recommended: `brew install uv`.
- **Targets:** macOS (arm64 / Intel) or supported Linux distros (see the role README). **macOS** also needs **Homebrew**, **Xcode + CLT** for Ballai-style CI, and network access to GitHub.

## Inventory

```bash
cp inventory.example inventory
```

**`inventory.example` is checked in** with the default Ballai layout: **`localhost`** plus a second Mac at **`ansible_host=192.168.1.51`**, **`ansible_user=ballew`**. Edit IP, user, or use **`*.local`** after `cp` to match your LAN.

Use **`[github_runners]`** for new setups. You can keep **`[mac_runners]`** for older inventories; those hosts are still included.

**`host foo.local` → NXDOMAIN:** normal. **`host`** / **`dig`** query unicast DNS, not Bonjour. That does not prove SSH to **`foo.local`** will fail—OpenSSH on macOS can still use mDNS. If **`ssh user@foo.local`** does fail, use the machine’s **LAN IP** in inventory (and reserve DHCP or update when the IP changes).

**SSH:** The controller must be able to SSH as **`ansible_user`** to each remote host (e.g. `ssh-copy-id` or an SSH agent key GitHub-style). Unreachable hosts are skipped after fact gathering; fix keys, then re-run the play.

## Options (extra vars)

Playbook variables (Ballai / legacy names) map into the Monolith role as shown.

| Variable | Default | Meaning |
|----------|---------|---------|
| `github_account` | `spooky-fox` | Repo or org owner for registration |
| `github_repo` | `ballai` | Repository name (when `runner_org: false`) |
| `runner_labels` | `[ballai-ci]` | List, or comma-separated string via `-e` |
| `runner_dir` | `$HOME/actions-runner` | Install directory |
| `runner_user` | `{{ ansible_user }}` | Unix user for the runner (set explicitly if needed) |
| `github_actions_runner_version` | `latest` | Passed to role as `runner_version` (leading `v` stripped if present) |
| `github_actions_runner_replace` | `false` | Maps to `reinstall_runner` (re-register / replace) |
| `github_actions_runner_install_service` | `true` | `true` → `runner_state: started`, `false` → `stopped` |
| `github_actions_runner_github_token_file` | `""` | Override path to token file (else `ansible/github_token`) |
| `github_actions_runner_become_password_file` | `""` | Override path to sudo password file (must exist if set) |
| `ballai_ansible_become_secret_id` | from env `BALLAI_ANSIBLE_BECOME_SECRET_ID` | If set and password still unset, load via `amazon.aws.aws_secret` lookup |
| `github_actions_runner_install_ci_tools` | `true` | macOS only: `brew install` swiftlint, xcodegen, xcbeautify after the role |

### Monolith role knobs (advanced CI)

Pass through any variable from the [role README](https://github.com/MonolithProjects/ansible-github_actions_runner/blob/master/README.md), for example:

- **`runner_org: true`** — organization runner; set `github_account` to the org.
- **`github_owner`**, **`runner_group`**, **`runner_name`**, **`runner_no_default_labels`**
- **`runner_extra_config_args`** — e.g. `--ephemeral` for disposable agents
- **`custom_env`** — proxy / env block for the runner `.env` file
- **`all_runners_in_same_repo: false`** — multiple repos in one play
- **`github_api_url`**, **`github_url`**, **`runner_on_ghes`** — GitHub Enterprise
- **`runner_state: absent`** — unregister and remove the runner

### Re-register the same machine

```bash
uv run ansible-playbook -i inventory playbooks/github_actions_runner.yml \
  -e github_actions_runner_replace=true
```

`ansible.cfg` sets **`interpreter_python = auto_silent`**, **`roles_path`** (**`roles/`** before **`.ansible/roles`**), and **`collections_path`**.

Workflow jobs must use labels matching `runner_labels` (e.g. **`ballai-ci`** in `spooky-fox/ballai` CI).
