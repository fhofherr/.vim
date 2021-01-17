import os
import shutil

from dotfiles import fs, module


class Bat(module.Definition):
    @property
    def cfg_dir(self):
        if self.home_dir != module.DEFAULT_HOME_DIR:
            return os.path.join(self.home_dir, ".config", "bat")
        try:
            return self.__cfg_dir
        except AttributeError:
            p = self.run_cmd("bat", "--config-dir", capture_output=True)
            self.__cfg_dir = p.stdout.decode("utf-8").strip()
        return self.__cfg_dir

    @property
    def cfg_file_src(self):
        return os.path.join(self.mod_dir, "config")

    @property
    def cfg_file_dest(self):
        return os.path.join(self.cfg_dir, "config")

    @property
    def bat_cmd(self):
        return shutil.which("bat")

    @module.install
    @module.update
    def install(self):
        # TODO enable skipping of module if bat is not installed
        if not self.bat_cmd:
            self.log.warn("bat is not installed")
            return
        fs.safe_link_file(self.cfg_file_src, self.cfg_file_dest)
        self.state.setenv("MANPAGER", "sh -c 'col -bx | bat -l man -p'")
        self.state.add_alias("cat", "bat")
