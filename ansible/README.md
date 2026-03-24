# Ansible (macOS GitHub Actions runner)

Playbook to install the official [actions/runner](https://github.com/actions/runner) on a Mac and register it against a repository (default: `spooky-fox/ballai` with label `ballai-ci`).

## Fully automated (no prompts)

1. **Install toolchain:** `brew install uv` then `cd ansible && uv sync`
2. **GitHub PAT on the controller** (the machine running Ansible), one of:
   - Create **`ansible/github_token`** with a single line (`ghp_...`, repo admin). **`chmod 600`**. (Gitignored.)
   - Or leave that file absent and set **`GITHUB_TOKEN`** in the environment.
3. **Optional sudo password file:** **`ansible/become_password`** (single line, `chmod 600`) only if you add **`become: true`** tasks or use **`ansible-playbook -b`**. The stock playbook does not use `become` for the runner install.
4. **Run:**

```bash
cd ansible
uv run ansible-playbook -i inventory playbooks/github_actions_runner_mac.yml
```

Copy examples: `cp github_token.example github_token` then replace the token; **`chmod 600 github_token`**.

**Non-interactive behavior**

- **`brew install gnu-tar`:** `HOMEBREW_NONINTERACTIVE=1`
- **`./svc.sh`:** user **LaunchAgent** under `~/Library/LaunchAgents` — **no sudo**, do not use Ansible **`become`** on these tasks.

## Requirements

- **Python 3.12+** and **ansible-core 2.20+** (see `pyproject.toml`). The play asserts Ansible’s version at runtime.
- **uv** recommended: `brew install uv` — avoids Homebrew Python **PEP 668** issues.
- **Alternative:** `python3 -m venv .venv` then `pip install -r requirements.txt` inside the venv.
- Target must be **macOS** (arm64 or Intel).
- **Homebrew** on the target for **gnu-tar** (required by `ansible.builtin.unarchive`).

## Inventory

```bash
cp inventory.example inventory
```

## Options (extra vars)

| Variable | Default | Meaning |
|----------|---------|---------|
| `github_repo` | `spooky-fox/ballai` | `owner/name` |
| `runner_labels` | `ballai-ci` | Comma-separated labels (no spaces) |
| `runner_dir` | `$HOME/actions-runner` | Install directory |
| `github_actions_runner_version` | `latest` | or pin e.g. `v2.333.0` |
| `github_actions_runner_replace` | `false` | Set `true` to re-run `config.sh --replace` |
| `github_actions_runner_install_service` | `true` | Run `./svc.sh install` / `start` as your user |
| `github_actions_runner_github_token_file` | `""` | Override path to token file (else `ansible/github_token`) |
| `github_actions_runner_become_password_file` | `""` | Override path to sudo password file (else `ansible/become_password`) |

### Re-register the same machine

```bash
uv run ansible-playbook -i inventory playbooks/github_actions_runner_mac.yml \
  -e github_actions_runner_replace=true
```

### Built-in Ansible equivalents

- **`ansible-playbook --become-password-file=...`** instead of `ansible/become_password`.

`ansible.cfg` sets **`interpreter_python = auto_silent`**.

Workflow jobs must use labels matching `runner_labels` (e.g. `ballai-ci` in `spooky-fox/ballai` CI).
