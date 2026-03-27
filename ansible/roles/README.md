# Bundled roles

## `monolithprojects.github_actions_runner`

Vendored from [MonolithProjects/ansible-github_actions_runner](https://github.com/MonolithProjects/ansible-github_actions_runner) **v1.27.0** (MIT). Upstream **`.github/`**, lint configs, and **`meta/.galaxy_install_info`** were removed as non-runtime.

### Local patches

**ansible-core 2.20+ compatibility:**

- Strict-boolean `when:` for macOS `svc.sh start` (no truthy string).
- `ansible_facts['distribution']` instead of legacy `ansible_distribution` in `become` templates.
- Clearer `runner_state` comparisons for restart `when:` (Unix + Windows).

**Technical debt cleanup (issue #23):**

- Replaced string-boolean `become` expressions (`"{{ 'false' if … else 'true' }}"`) with real booleans (`"{{ ansible_facts.system != 'Darwin' }}"`).
- Normalized YAML boolean style: `yes`/`no` → `true`/`false`.
- Reduced excessive `sleep 5` to `sleep 2` in service restart (Unix).
- Extracted duplicated GitHub URL construction (`github_full_api_url` and `github_full_url` `set_fact` blocks) into shared `tasks/resolve_github_url.yml`, included from `collect_info.yml`, `install_runner_unix.yml`, and `install_runner_win.yml`.

### How to update from upstream

1. Install the Galaxy role into a scratch location:
   ```
   ansible-galaxy role install monolithprojects.github_actions_runner -p .ansible/roles
   ```
2. Diff the scratch copy against this vendored tree:
   ```
   diff -ru .ansible/roles/monolithprojects.github_actions_runner ansible/roles/monolithprojects.github_actions_runner
   ```
3. Apply upstream changes, then re-apply local patches listed above.
4. Bump the version note in this file and in `requirements.yml`.

`ansible.cfg` **`roles_path`** prefers this directory over **`.ansible/roles`** from `ansible-galaxy role install`.
