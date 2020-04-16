import os
import shutil
import venv

from invoke import task

from dotfiles import common, logging, state, fs, git
from dotfiles.tasks import pipx

_LOG = logging.get_logger(__name__)

PYTHON_TOOLS_AND_LINTERS = [
    "ansible-lint", "gitlint", "neovim-remote", "yamllint"
]


@task
def install(c, home_dir=common.HOME_DIR, install_nvim_plugins=False):
    nvim_cmd = shutil.which("nvim")
    if not nvim_cmd:
        _LOG.warn("neovim is not installed")
        return

    pip_cmd = venv_pip_path(home_dir, mkdir=True, recreate=True)
    python_cmd = venv_python_path(home_dir)

    c.run(f"{pip_cmd} install --upgrade pip")
    c.run(f"{pip_cmd} install --upgrade pynvim")

    for tool in PYTHON_TOOLS_AND_LINTERS:
        pipx.install_pkg(c, tool, home_dir=home_dir)

    vim_cfg_src = os.path.join(common.ROOT_DIR, "configs", "vim")
    vim_cfg_dest = os.path.join(common.xdg_config_home(home_dir), "nvim")
    fs.safe_link_file(vim_cfg_src, vim_cfg_dest)

    if install_nvim_plugins:
        c.run(f"{nvim_cmd} -E -c 'PlugUpdate' -c 'qall!'",
              hide="stdout",
              env={"DOTFILES_NEOVIM_PYTHON3": python_cmd})

    nvim_state = state.State(name="nvim")
    nvim_state.put_env("DOTFILES_NEOVIM_PYTHON3", python_cmd)
    nvim_state.put_env("EDITOR", nvim_cmd)
    nvim_state.add_alias("vim", nvim_cmd)
    nvim_state.add_alias("view", f"{nvim_cmd} -R")

    after_compinit_script = os.path.join(common.ROOT_DIR, "configs", "vim",
                                         "after_compinit.zsh")
    with open(after_compinit_script) as f:
        nvim_state.after_compinit_script = f.read()

    state.write_state(home_dir, nvim_state)


@task
def install_appimage(c, home_dir=common.HOME_DIR, version="nightly"):
    _LOG.info("Install nvim appimage")

    nvim_cmd = appimage_cmd_path(home_dir, mkdir=True)
    with git.github_release("neovim/neovim", version=version) as gh_r:
        asset = gh_r.download_asset("nvim.appimage")
        shutil.copy(asset, nvim_cmd)
        os.chmod(nvim_cmd, 0o755)


def appimage_cmd_path(home_dir, mkdir=False):
    return os.path.join(common.bin_dir(home_dir, mkdir=mkdir), "nvim")


def venv_dir_path(home_dir, mkdir=False, recreate=False):
    venv_dir = os.path.join(home_dir, ".local", "dotfiles", "nvim.venv")
    if mkdir and (not os.path.exists(venv_dir) or recreate):
        venv.create(venv_dir, clear=recreate, with_pip=True)
    return venv_dir


def venv_bin_dir_path(home_dir, mkdir=False, recreate=False):
    venv_dir = venv_dir_path(home_dir, mkdir=mkdir, recreate=recreate)
    return os.path.join(venv_dir, "bin")


def venv_python_path(home_dir, mkdir=False, recreate=False):
    bin_dir = venv_bin_dir_path(home_dir, mkdir=mkdir, recreate=recreate)
    return os.path.join(bin_dir, "python3")


def venv_pip_path(home_dir, mkdir=False, recreate=False):
    bin_dir = venv_bin_dir_path(home_dir, mkdir=mkdir, recreate=recreate)
    return os.path.join(bin_dir, "pip")
