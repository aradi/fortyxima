Style guide
===========

The main leading principle when contributing code to the Fortyxima library
should be readability. If your code can not be easily read and understood by
others, it will be hard to maintain and extend it. It should also fit well to
existing parts of the library (in style as well as in its programming paradigms)
maintaining the principle of least surprise.

Below, you find some explicit coding rules we try to follow. The list can not
cover all aspects, so also look at the existing source code and try to follow
the conventions in it.


Line length and indentation
---------------------------

* Maximal **line length** is **80** characters. For lines longer than that, use
  continuation lines.

* **Nested blocks** are indented by **+2** whitespaces::
    
     write(*, *) "Nested block follows"
     do ii = 1, 100
       write(*, *) "This is the nested block"
       if (ii == 50) then
         write(*, *) "Next nested block"
       end if
     end do

* **Continuation lines** are indented by **+4** whitespaces. Make sure to
  place continuation characters (`&`) both at the end of the line as well as at
  the beginning of the continuation line::

      call someRoutineWithManyParameters(param1, param2, param3, param4, &
          & param5)



Case conventions
----------------

* **Variable** names follow the **lowerCamelCase** convention::

      logical :: hasComponent

* **Constants** (parameters) use **UPPER_CASE_WITH_UNDERSCORE**::
    
      integer, parameter :: MAX_ARRAY_SIZE = 100

  with the exception of constants used to define the kind parameter for
  intrinsic types, as those should be all lowercase (and short)::

      integer, parameter :: wp = kind(1.0d0)
      
      real(wp) :: val


* **Subroutine** and **function** names follow also the **lowerCamelCase**
  notation::

      subroutine testSomeFunctionality()

      myValue = getSomeValue(...)


* **Type** (object) names are written **UpperCamelCase**::

      type :: RealList

      type(RealList) :: myList
      

* **Module** names follow **lower_case_with_underscore** convection::

      use fortyxima_filesys

  Underscores are used for namespacing.
