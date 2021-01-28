import os
import textwrap
from dataclasses import dataclass
from typing import List

from dotfiles import state


@dataclass
class Plugin:
    url: str
    main_file: str

    def init_script(self, plugin_dir):
        main_file = os.path.join(plugin_dir, self.main_file)
        return textwrap.dedent(f"""
        #
        # Plugin: {self.url}
        #
        source "{main_file}"
        fpath+=("{plugin_dir}")
        """)


def write_init_files(dest_dir: str, sts: List[state.State]):
    header = "# File auto-generated; DO NOT EDIT"

    agg = state.Aggregate()
    for st in sts:
        agg.add_state(st)

    with open(os.path.join(dest_dir, "env.zsh"), "w") as f:
        def merge_path(path_entries):
            this_venv = os.getenv("VIRTUAL_ENV")
            old_path = os.getenv("PATH").split(os.pathsep)
            entries_set = set(path_entries)
            for v in old_path:
                if v in entries_set:
                    continue
                if this_venv and v.startswith(this_venv):
                    continue
                path_entries.append(v)
            return os.pathsep.join(path_entries)

        f.write(f"{header}\n\n")
        for name, val in agg.env_vars:
            if name == "PATH":
                f.write(f"export DOTFILES_OLD_PATH=\"$PATH\"\n")
                f.write(f"export PATH=\"{merge_path(val)}\"\n")
                continue
            val = str(val)
            # Escape any single quotes: https://stackoverflow.com/a/1315213
            val = val.replace("'", r"'\''")
            f.write(f"export {name}='{val}'\n")

    with open(os.path.join(dest_dir, "aliases.zsh"), "w") as f:
        f.write(f"{header}\n\n")
        for name, val in agg.aliases:
            f.write(f"alias {name}='{val}'\n")

    with open(os.path.join(dest_dir, "before_compinit.zsh"), "w") as f:
        f.write(f"{header}\n\n")
        f.write(agg.zsh_before_compinit_script)
        f.write("\n")

    with open(os.path.join(dest_dir, "after_compinit.zsh"), "w") as f:
        f.write(f"{header}\n\n")
        f.write(agg.zsh_after_compinit_script)
        f.write("\n")
