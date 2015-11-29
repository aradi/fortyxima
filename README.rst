===============================================
Fortyxima - Boosting Fortran to its superlative
===============================================

The Fortyxima library contains type extensions, interfaces and macros
(templates) for the Fortran 2008 language, which should facilitate its usage for
general purpose programming.

The package is available under the term of the BSD 2-Clause License (see the
`LICENSE` file).


Package content
===============

The library contains currently following language extensions:

**filesys** 
File system manipulation (creating/deleting directories, symbolic links, etc..)
by using Fortran-friendly wrappers around appropriate libc-routines.

Additionally Fortyxima offers following tools:

**m4fpp** 
Fortran preprocessor based on the general purpose macro language M4. It gives
you much higher flexibility in defining templates in Fortran as CPP. It offers
similar basic constructs as CPP (`_if`, `_ifdef`, etc.) and some add-ons to
support the creation of reliable programs (e.g. asserts, marking code sequence
to be included only in debug mode, etc.).

**waf**
Some extension modules to the general purpose build tool `waf <http://waf.io>`_,
to make it more suitable for Fortran/C based scientific projects.
