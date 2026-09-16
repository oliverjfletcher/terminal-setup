# terminal-setup

Single-shot bootstrap for a fresh macOS machine: Xcode CLT, Homebrew, a curated
set of packages and apps, shell plugins, and dotfiles.

Inspired by [@kbdevops](https://github.com/kbdevops).

## Install

```bash
git clone https://github.com/oliverjfletcher/terminal-setup.git
cd terminal-setup
./install.sh
```

You get an interactive picker for what to install:

```
Select what to install
  up/down or j/k move | space toggles | a all | n none | enter confirm | q quit

 ❯ ◉ core         Shell, search, git, everyday CLI
   ◉ dev          Languages, build tools, linters
   ◉ kubernetes   kubectl, helm, k9s, argo, flux
   ◉ cloud        Terraform, Azure, GCP, Ansible
   ◯ aws          AWS CLI, CDK, SAM, CloudFormation
   ◉ security     gpg, sops, age, trivy, nmap
   ◉ apps         GUI apps (casks) - may need your password
   ◉ fonts        Nerd Fonts for the terminal prompt
   ◉ python       Python CLI tools via uv
   ◉ plugins      tmux tpm, vim lightline, fzf keys
   ◉ dotfiles     Copy dotfiles/ into $HOME
```

Then a live progress bar per group:

```
[3/12] Packages: core
      ████████████░░░░░░░░░░░░░░  46% (16/35) git-delta
```

### Options

| Flag | Effect |
| --- | --- |
| `--yes`, `-y` | Non-interactive; installs the default groups |
| `--only core,apps` | Only these groups |
| `--skip aws,fonts` | Defaults minus these groups |
| `--dry-run` | Show what would happen, change nothing |
| `--list` | Print the groups and their defaults |
| `--help` | Usage |

The script is safe to re-run: every package, clone and dotfile is checked before
it is touched, and a full log is written to `$TMPDIR/terminal-setup-*.log`.

## Capturing changes back

```bash
./backup-dotfiles.sh          # copy $HOME dotfiles into dotfiles/
./backup-dotfiles.sh --brew   # also snapshot installed packages for diffing
```

## Layout

```
install.sh            interactive bootstrap
backup-dotfiles.sh    $HOME -> repo, curated allowlist
brew/Brewfile.*       one file per package group
dotfiles/             source of truth for shell + editor config
python-tools.txt      Python CLI tools installed with `uv tool install`
```

## After installing

1. Restart the terminal, or `exec zsh`.
2. Set the terminal font to **MesloLGS Nerd Font** so the prompt glyphs render.
3. In tmux, press `prefix + I` to fetch plugins.
4. Sign in: `gh auth login`, `gcloud auth login`, `az login`.

Machine-specific settings that should not be committed go in `~/.zshrc.local`,
which `.zshrc` sources if present.
