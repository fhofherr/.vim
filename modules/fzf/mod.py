import os
import shutil
import textwrap

from dotfiles import module

REPO_URL = "https://github.com/junegunn/fzf"


class FZF(module.Definition):
    required = ["git"]
    optional = ["bat"]

    @property
    def _repo_dir(self):
        return os.path.join(self.projects_dir, "github.com", "junegunn", "fzf")

    @property
    def _fzf_bin_dir(self):
        return os.path.join(self._repo_dir, "bin")

    @property
    def fzf_cmd(self):
        return os.path.join(self._fzf_bin_dir, "fzf")

    @property
    def _after_compinit_txt(self):
        return textwrap.dedent(f"""
        if command -v fd >/dev/null 2>&1; then
            _fzf_compgen_path() {{
                 command fd  --type file --hidden --follow --exclude ".git" . "$1"
            }}

            _fzf_compgen_dir() {{
                command fd --type d --hidden --follow --exclude ".git" . "$1"
            }}
        fi

        # FZF Auto-completion
        [[ $- == *i* ]] && source "{self._repo_dir}/shell/completion.zsh" 2> /dev/null

        # FZF Key bindings
        source "{self._repo_dir}/shell/key-bindings.zsh"

        bindkey '^P' fzf-file-widget
        """)

    @module.update
    @module.install
    def install(self):
        self.git.clone_or_update(REPO_URL, self._repo_dir, depth=1)
        # Download only.
        self.run_cmd("./install",
                     "--bin",
                     "--no-update-rc",
                     cwd=self._repo_dir)
        self.state.setenv("PATH", self._fzf_bin_dir)
        self.state.zsh.after_compinit_script = self._after_compinit_txt

        if self.bat:
            preview = (
                f"{self.bat.bat_cmd} --style=numbers,changes  " +
                "--line-range=:15 --color always {} " +  # Literal {}
                "2> /dev/null")
            self.state.setenv("FZF_CTRL_T_OPTS", f"--preview '{preview}'")

        fd = shutil.which("fd")
        if fd:
            default_cmd = f"{fd} --type file --hidden --follow --exclude '.git'"
            self.state.setenv("FZF_DEFAULT_COMMAND", default_cmd)
            self.state.setenv("FZF_CTRL_T_COMMAND", default_cmd)
            self.state.setenv("FZF_DEFAULT_OPTS", "--layout=reverse --inline-info")


if __name__ == "__main__":
    module.run(FZF)
