from dotfiles import module

PKG_NAMES = [
    "litecli",
    "mycli",
    "pgcli",
]


class DBCLI(module.Definition):
    required = ["pipx"]
    hostnames = ["fhhc", "wintermute"]

    @module.install
    def install(self):
        for pkg_name in PKG_NAMES:
            self.pipx.install(pkg_name)

    @module.update
    def update(self):
        for pkg_name in PKG_NAMES:
            self.pipx.update(pkg_name)


if __name__ == "__main__":
    module.run(DBCLI)
