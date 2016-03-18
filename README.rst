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

The library currently contains following module:

**filesys** 
File system manipulation (creating/deleting directories, symbolic links, etc..)
by using Fortran-friendly wrappers around appropriate libc-routines.

**unittest**
Unit testing framework (also used by Fortyxima to test itself).


Installing
==========


Requirements
------------

* Fortran 2003 compatible compiler

* C compiler

* Python interpreter (2.7, 3.2 or above)

* The `Fypp preprocessor <https://bitbucket.org/aradi/fypp>`_.


Building the library
--------------------

The project uses the `waf building framework <http://waf.io>`_. First configure
your project by::

  ./waf configure

If you want to make let `waf` to look for a specific compiler issue::

  ./waf configure --check-fortran-compiler=COMPILER

where ``COMPILER`` is the name of the compiler (e.g. ``gfortran``, ``ifort``,
``fc_nag``, etc.). After the configuration you can build the project by::

  ./waf build

In order to run the unittests, use ::

  ./waf test
