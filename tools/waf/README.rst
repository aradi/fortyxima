This folder contains various extensions to waf, which should enhance its
applicability for Fortran/C-based scientific projects.

`build-waf`
    Use this script to build a waf executable for your project. The waf
    executable will contain the Fortran- and C-related waf modules as well as
    some general extensions from the Fortyxima tree. You will need to have an
    unpacked waf source somewhere (see `build-waf --help`).


`extras/`
    Folder for general purpose waf extensions, which will be added to your waf
    executable unless you specify it otherwise. (They try to follow closely the
    official waf style, so that they can be added to the official waf repository
    at some point.)


`fortyxima/`
    Fortyxima specific modules, only used to tailor waf for compiling the
    library. They are not added to the waf executable.
