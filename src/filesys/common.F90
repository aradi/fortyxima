!> Helper routines for the libcfx library.
!! \cond HIDDEN
module fortyxima_filesys_common
  use, intrinsic :: iso_fortran_env
  use, intrinsic :: iso_c_binding
  use fortyxima_filesys_libciface
  use fortyxima_filesys_libcwrapiface
  implicit none
  private

  public :: f_c_string, c_f_string, f_cptr_string, cptr_f_string
  public :: handle_errorcode

  integer, parameter :: stdout = output_unit
  integer, parameter :: stderr = error_unit

contains

  !> Converts a Fortran type string in a 0-char terminated C-type string.
  !! \param fstring  Fortran character variable.
  !! \return 0-char terminated string.
  function f_c_string(fstring) result(cstring)
    character(*, kind=c_char), intent(in) :: fstring
    character(:, kind=c_char), allocatable :: cstring

    cstring = trim(fstring) // c_null_char

  end function f_c_string
  

  !> Converts a 0-char terminated C-type string into a Fortran string.
  !! \param cstring  C-type 0-char terminated string.
  !! \return Fortran character variable.
  function c_f_string(cstring) result(fstring)
    character(*, kind=c_char), intent(in) :: cstring
    character(:, kind=c_char), allocatable :: fstring

    fstring = cstring(1:len(cstring)-1)

  end function c_f_string


  !> Converts a 0-char terminated C-type string into a Fortran string.
  !! \param cptr  C-type pointer pointing to the C-type string.
  !! \param fstring  Fortran string on exit
  !! \param dealloc  If set to .true., the C character string will be
  !!     deallocated and cptr unassociated.
  !! \return Fortran character variable.
  subroutine cptr_f_string(cptr, fstring, dealloc)
    type(c_ptr), intent(inout) :: cptr
    character(:, kind=c_char), allocatable, intent(out) :: fstring
    logical, intent(in), optional :: dealloc
    
    integer(c_size_t) :: slen
    character(kind=c_char), pointer :: fptr(:)

    slen = libc_strlen(cptr)
    call c_f_pointer(cptr, fptr, [ slen + 1 ])
    allocate(character(slen) :: fstring)
    fstring = transfer(fptr, fstring)
    if (present(dealloc)) then
      if (dealloc) then
        call freestring_c(cptr)
      end if
    end if
    
  end subroutine cptr_f_string
    
  
  !> Converts a Fortran string into a 0 terminated C-string.
  !! \param fstring  Fortran string.
  !! \return C-pointer pointing to a C-string with the same content as fstring.
  function f_cptr_string(fstring) result(cptr)
    character(*, kind=c_char), intent(in) :: fstring
    type(c_ptr) :: cptr
    
    cptr = copystring_c(f_c_string(fstring))

  end function f_cptr_string
    
  
  !> Handles error code.
  !! \param errorcode  Error code as returned by a libc call.
  !! \param msg  Error message to print out.
  !! \param errorarg Optional error argument. If present, it will be filled
  !!   with the value of errocode. If not present and errocode differs from
  !!   zero, the subroutine writes the appropriate message and stops.
  subroutine handle_errorcode(errorcode, msg, errorarg)
    integer(c_int), intent(in) :: errorcode
    character(*), intent(in) :: msg
    integer(c_int), intent(out), optional :: errorarg
    
    if (present(errorarg)) then
      errorarg = errorcode
    elseif (errorcode /= 0) then
      write(stderr, "(A)") "Uncaught error code!"
      write(stderr, "(A)") msg
      write(stderr, "(A,I0)") "Error code: ", errorcode
      error stop 1
    end if

  end subroutine handle_errorcode


end module fortyxima_filesys_common

!> \endcond
