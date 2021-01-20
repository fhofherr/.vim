import argparse
import copy
import importlib.abc
import importlib.util
import os
import subprocess
from dataclasses import dataclass
from logging import Logger
from typing import (Any, Callable, Dict, Generator, List, Optional, Set, Tuple,
                    Type, TypeVar, Union)

from dotfiles import fs, logging, state, zsh

DEFAULT_HOME_DIR = os.path.expanduser("~")
DEFAULT_DIR = os.path.join(fs.find_dotfiles_dir(), "modules")

# Will later be joined with the passed home directory.
_DEFAULT_STATE_DIR = os.path.join(".local", "dotfiles", "state")

_DEFAULT_SHELL = os.path.basename(os.getenv("SHELL", "zsh"))

T = TypeVar("T", bound="Definition")

# TODO some modules may have @module.install and @module.update applied to
# the same method. Take this into account when wrapping the methods into
# functions (provided this is ever necessary).


def install(f):
    f._installer = True
    return f


def update(f):
    f._updater = True
    return f


def uninstall(f):
    f._uninstaller = True
    return f


def export(f):
    f._exported = True
    return f


class Definition:
    """
    Definition is the base class for all module definitions.

    Subclasses must make sure to call Definition.__init__ if they need to
    implement their own __init__ method. The signature of __init__ must not
    change when re-implemented.

    mod_dir is the path of the directory in which the module definition is
    located, home_dir the path of the directory which should be treated as the
    executing users home directory.  During instantiation a path different from
    the value in $HOME may be returned. Modules must use home_dir instead of
    $HOME.
    """

    # Name of the module. Defaults to the lower-case class name.
    name: Optional[str] = None

    # List of required modules.
    required: List[str] = []

    # List of optional modules.
    optional: List[str] = []

    # List of tags for this module.
    tags: List[str] = []

    @classmethod
    def _new_instance(cls: Type[T], mod_dir: str, home_dir: str,
                      state_dir: str, mod_reg: Dict[str, "Definition"]) -> T:
        """
        Creates a new instance of the class extending Definition.

        After creation any dependencies defined in the class are looked up in
        mod_reg and added as fields to the newly created instance.
        """
        assert cls.name
        mod = cls(mod_dir, home_dir, state.load_state(state_dir, cls.name),
                  logging.get_logger(cls.name))
        for dep_name in cls.required:
            dep = mod_reg[dep_name]
            setattr(mod, dep_name, _Protector(dep))
        for dep_name in cls.optional:
            opt_dep = mod_reg.get(dep_name)
            if not opt_dep:
                setattr(mod, dep_name, None)
                continue
            setattr(mod, dep_name, _Protector(opt_dep))

        return mod

    def __init__(self, mod_dir: str, home_dir: str, state: state.State,
                 log: Logger):
        self._mod_dir = mod_dir
        self._home_dir = home_dir
        self._log = log
        self._state = state

    @property
    def mod_dir(self):
        return self._mod_dir

    @property
    def home_dir(self):
        return self._home_dir

    # TODO determine this based on XDG_CONFIG_HOME as well?
    @property
    def cache_dir(self):
        return os.path.join(self.home_dir, ".cache", "dotfiles", self.name)

    @property
    def local_dir(self):
        return os.path.join(self.home_dir, ".local", "dotfiles", self.name)

    @property
    def download_dir(self):
        return os.path.join(self.cache_dir, "downloads")

    @property
    def bin_dir(self):
        return os.path.join(self.local_dir, "bin")

    @property
    def state(self) -> state.State:
        return self._state

    @property
    def log(self) -> Logger:
        return self._log

    def _run(self, cmd, state_dir):
        marker = {
            "install": "_installer",
            "update": "_updater",
            "uninstall": "_uninstaller",
        }[cmd]
        op = None

        # Search in self and the objects mro's dict for any callables
        # that have the marker.
        #
        # In contrast to calling getattr directly on self, this avoids
        # properties being evaluated.
        #
        # See: https://stackoverflow.com/a/3681323
        callables = []
        for obj in [self] + self.__class__.mro():
            for name, val in obj.__dict__.items():
                if callable(val) and hasattr(val, marker):
                    callables.append((name, val))

        if len(callables) == 0:
            raise InvalidCommandError(
                f"{self.name}: cannot execute {cmd}: " +
                f"no callable with marker '{marker}' found")
        if len(callables) > 1:
            raise InvalidCommandError(
                f"Cannot execute {cmd}: " +
                f"more than one callable with marker '{marker}' found: " +
                ", ".join(n for (n, _) in callables))
        _, op = callables[0]
        op(self)
        state.save_state(state_dir, self.state)

    def run_cmd(self, cmd: str, *args, **kwargs):
        self.log.info(f"Executing {cmd} {' '.join(args)}")
        if "check" not in kwargs:
            kwargs["check"] = True
        return subprocess.run([cmd, *args], **kwargs)


def _ensure_definition_name(mod_def: Type[Definition]):
    if mod_def.name is None or mod_def.name == "":
        mod_def.name = mod_def.__name__.lower()


class _Protector:
    def __init__(self, mod: Definition):
        self._mod = mod

    def __getattr__(self, name):
        # Raises attribute error if self._mod has no such attribute
        attr = getattr(self._mod, name)
        # TODO protect attributes whose name starts with a single underscore
        if not callable(attr) or (hasattr(attr, "_exported")
                                  and attr._exported):
            return attr
        raise AttributeError(
            f"attribute '{name}' of '{self._mod.name}' is not exported")

    def __call__(self, *args, **kwargs):
        if not callable(self._mod):
            raise TypeError(f"'{self._mod.name}' is not callable")
        if not self._mod.__call__._exported:
            raise AttributeError(
                f"'__call__' method of '{self._mod.name}' is not exported")
        return self._mod(*args, **kwargs)


class InvalidCommandError(Exception):
    pass


def _parse_args(
    mods_dir: str,
    home_dir: str,
    state_dir: str,
):
    args_parser = argparse.ArgumentParser(
        description="Execute dotfiles modules")
    args_parser.add_argument(
        "--modules-dir",
        type=str,
        default=mods_dir,
        help=f"Directory containing modules. Default: {mods_dir}")
    args_parser.add_argument(
        "--home-dir",
        type=str,
        default=home_dir,
        help=f"Directory to use as user home directory. Default: {home_dir}")
    args_parser.add_argument(
        "--state-dir",
        type=str,
        default=state_dir,
        help=("Directory containing state of installed modules. Treated as " +
              "relative to home directory if not an absolute path. " +
              f"Default: $HOME/{state_dir}"))
    args_parser.add_argument("-t",
                             "--tag",
                             type=str,
                             nargs="*",
                             dest="tags",
                             help="Tags to limit the modules by")
    args_parser.add_argument(
        "--shell",
        default=_DEFAULT_SHELL,
        help="Shell for which initialization code should be generated")
    args_parser.add_argument("cmd", choices=["install", "update", "uninstall"])
    return args_parser.parse_args()


def run(only: Optional[Union[Type[Definition], str]] = None,
        mods_dir: str = DEFAULT_DIR,
        home_dir: str = DEFAULT_HOME_DIR,
        state_dir: str = _DEFAULT_STATE_DIR,
        loader: Optional["Loader"] = None):

    args = _parse_args(mods_dir, home_dir, state_dir)

    # TODO the uninstall command needs special treatment: only modules that
    # have no other modules depending on them may be uninstalled.
    if args.cmd == "uninstall":
        raise NotImplementedError("uninstall is not yet implemented")

    if args.state_dir == _DEFAULT_STATE_DIR:
        args.state_dir = os.path.join(args.home_dir, args.state_dir)
    if not loader:
        loader = Loader(args.modules_dir, args.home_dir, args.state_dir)

    load_args: Dict[str, Any] = {}
    if args.tags:
        load_args["filter_by"] = [has_any_tag(args.tags)]
    if only:
        load_args["reduce_by"] = [reduce_by_mod(only)]

    mods, mods_by_name = loader.load(**load_args)
    for mod in mods:
        mod._run(args.cmd, args.state_dir)

    # TODO if only one module is selected only the state of that module is
    #      used to generate a new shell config. This is not what we want.
    if not only and args.shell == "zsh":
        dest_dir = os.path.join(args.home_dir, ".local", "dotfiles", "zsh")
        sts = [m.state for m in mods]
        zsh.write_init_files(dest_dir, sts)

    return mods


class Loader:
    @dataclass
    class ModInfo:
        mod_dir: str
        mod_def: Type[Definition]

    def __init__(self, mod_dir: str, home_dir: str, state_dir: str):
        self._mod_dir = mod_dir
        self._home_dir = home_dir
        self._state_dir = state_dir

    def load(
        self,
        reduce_by: List[Callable[[List["Loader.ModInfo"]],
                                 List["Loader.ModInfo"]]] = [],
        filter_by: List[Callable[["Loader.ModInfo"], "Loader.ModInfo"]] = [],
    ) -> Tuple[List[Definition], Dict[str, Definition]]:
        mod_infos = []

        for mod_dir, py_mod_name, mod_file in self._find_modules():
            for mod_def in self._load_mod_def(f"modules.{py_mod_name}",
                                              mod_file):
                _ensure_definition_name(mod_def)
                m = Loader.ModInfo(mod_dir=mod_dir, mod_def=mod_def)
                mod_infos.append(m)

        for r in reduce_by:
            mod_infos = r(mod_infos)

        for f in filter_by:
            mod_infos = [m for m in mod_infos if f(m)]

        mod_infos = sort_by_dependencies(mod_infos)

        mods_by_name: Dict[str, Definition] = {}
        mods = []
        for m in mod_infos:
            mod = m.mod_def._new_instance(m.mod_dir, self._home_dir,
                                          self._state_dir, mods_by_name)
            assert m.mod_def.name
            mods_by_name[m.mod_def.name] = mod
            mods.append(mod)

        return mods, mods_by_name

    def _find_modules(self) -> Generator[Tuple[str, str, str], None, None]:
        with os.scandir(self._mod_dir) as it:
            for entry in it:
                if not entry.is_dir():
                    continue
                mod_file = os.path.join(entry.path, "mod.py")
                if not os.path.isfile(mod_file):
                    continue
                py_mod_name = os.fsdecode(entry.name)
                yield (entry.path, py_mod_name, mod_file)

    def _load_mod_def(self, py_mod_name: str, mod_file: str):
        spec = importlib.util.spec_from_file_location(py_mod_name, mod_file)
        py_mod = importlib.util.module_from_spec(spec)

        assert isinstance(spec.loader, importlib.abc.Loader)
        spec.loader.exec_module(py_mod)
        for attr in dir(py_mod):
            v = getattr(py_mod, attr)
            try:
                if issubclass(v, Definition):
                    yield v
            except TypeError:
                continue


def has_any_tag(tags: List[str]) -> Callable[[Loader.ModInfo], bool]:
    """
    Filter mod_info for modules with at least one tag in tags assigned.
    If tags is empty mod_infos is returned verbatim.
    """
    def filter_fn(mod_info: Loader.ModInfo) -> bool:
        if not tags:
            return True
        for tag in mod_info.mod_def.tags:
            if tag in tags:
                return True
        return False

    return filter_fn


def reduce_by_mod(
    only: Union[Type[Definition], str]
) -> Callable[[List[Loader.ModInfo]], List[Loader.ModInfo]]:
    def append_optional_deps(deps, opt_deps, mods_by_name):
        for opt in opt_deps:
            if opt not in mods_by_name:
                continue
            deps.append(opt)

    def reducer(mod_infos: List[Loader.ModInfo]):
        mods_by_name = dict((m.mod_def.name, m) for m in mod_infos)
        if isinstance(only, str):
            mod_info = mods_by_name[only]
        else:
            _ensure_definition_name(only)
            mod_info = mods_by_name[only.name]

        result = [mod_info]
        deps = copy.deepcopy(mod_info.mod_def.required)
        append_optional_deps(deps, mod_info.mod_def.optional, mods_by_name)

        while deps:
            dep_name = deps.pop()
            dep = mods_by_name[dep_name]
            result.append(dep)
            deps.extend(dep.mod_def.required)
            append_optional_deps(deps, dep.mod_def.optional, mods_by_name)
        return result

    return reducer


def sort_by_dependencies(
        mod_infos: List[Loader.ModInfo]) -> List[Loader.ModInfo]:
    """
    Topologically sorts mod_infos by the module definitions list of required
    dependencies.

    Topological sort is done using Kahn's algorithm
    (https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm)
    """
    # First compile a list of module infos with no dependencies and a mapping
    # from modules with at least one dependency to their respective
    # dependencies.
    no_deps: List[Loader.ModInfo] = []
    with_deps: Dict[str, Set[str]] = {}
    by_name: Dict[str, Loader.ModInfo] = {}

    for mod_info in mod_infos:
        assert mod_info.mod_def.name  # Set, or inferred during loading
        name = mod_info.mod_def.name

        by_name[name] = mod_info
        opt_deps = {opt for opt in mod_info.mod_def.optional if opt in by_name}
        if not mod_info.mod_def.required and not opt_deps:
            no_deps.append(mod_info)
            continue
        with_deps[name] = set(mod_info.mod_def.required).union(opt_deps)

    sorted_infos = []
    while no_deps:
        # Remove the first element without dependencies from no_deps and
        # add it to the list of sorted infos.
        info = no_deps.pop()
        sorted_infos.append(info)

        # Then remove the info from all module infos that list it as a
        # dependency. If an entry in with_deps points to an empty set, remove
        # it from with_deps and add the module info to no_deps.

        # Copy with_deps.keys into a list to allow modifying with_deps during
        # iteration.
        for name in list(with_deps.keys()):
            # load_modules set this name if it was None
            assert info.mod_def.name is not None
            if info.mod_def.name not in with_deps[name]:
                continue
            with_deps[name].remove(info.mod_def.name)
            if not with_deps[name]:
                no_deps.append(by_name[name])
                del with_deps[name]

    # If with_deps is not empty by now, the contained modules have cyclic
    # dependencies.
    if with_deps:
        unmet = [f"{n}: {' -> '.join(vs)}" for n, vs in with_deps.items()]
        msg = "\n\t".join(unmet)
        msg = f"Unmet or cyclic module dependencies:\n\n{msg}"
        raise DependencyError(msg)

    return sorted_infos


class DependencyError(Exception):
    pass
