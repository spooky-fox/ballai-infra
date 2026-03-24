# Bundled roles

## `monolithprojects.github_actions_runner`

Vendored from [MonolithProjects/ansible-github_actions_runner](https://github.com/MonolithProjects/ansible-github_actions_runner) **v1.27.0** (MIT). Upstream **`.github/`**, lint configs, and **`meta/.galaxy_install_info`** were removed as non-runtime. **Local patches** for ansible-core 2.20+:

- Strict-boolean `when:` for macOS `svc.sh start` (no truthy string).
- `ansible_facts['distribution']` instead of legacy `ansible_distribution` in `become` templates.
- Clearer `runner_state` comparisons for restart `when:` (Unix + Windows).

`ansible.cfg` **`roles_path`** prefers this directory over **`.ansible/roles`** from `ansible-galaxy role install`.

To refresh from upstream: install the Galaxy role into `.ansible/roles`, diff against this tree, re-apply patches, bump the version note here and in `requirements.yml`.
