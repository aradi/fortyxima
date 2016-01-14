===============================================
Fortyxima - Boosting Fortran to its superlative
===============================================

The Fortyxima library contains types, interfaces and macros (templates) for the
Fortran 2008 language, which should facilitate its usage for general purpose
programming.

The package is available under the terms of the BSD 2-Clause License (see 
`LICENSE` file).


Package content
===============

The library contains following modules:

**filesys** 
File system manipulation (creating/deleting directories, symbolic links, etc..)
by using Fortran-friendly wrappers around appropriate libc-routines.


Additionally Fortyxima contains following tools:

**m4fpp** 
Fortran preprocessor based on the general purpose macro language M4. It offers
higher flexibility in defining templates in Fortran as CPP (e.g. multiline
macros are possible). It has similar basic constructs as CPP (`_IF`,
`_IFDEF`, etc.) with additional tools for for supporting the creation of
reliable programs (e.g. asserts, marking code sequences to be included only in
debug mode, etc.).

**waf**
Extension modules to the general purpose build tool `waf <http://waf.io>`_,
customizing it more for Fortran projects.
