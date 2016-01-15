!> Wrappers for the C-functions
!! \cond HIDDEN
module fortyxima_filesys_libcwrapiface
  use, intrinsic :: iso_c_binding
  implicit none
  
  interface
    !> Delivers the next entry within a directory.
    function nextdirentry_name_c(dirptr) &
        & bind(c, name='fortyxima_filesys_nextdirentry_name') result(res)
      import :: c_ptr
      type(c_ptr), value :: dirptr
      type(c_ptr) :: res
    end function nextdirentry_name_c

    !> Returns the name field of a directory entry.
    function direntry_name_c(direntry) &
        & bind(c, name='fortyxima_filesys_direntry_name') result(res)
      import :: c_ptr
      type(c_ptr), value :: direntry
      type(c_ptr) :: res
    end function direntry_name_c

    !> Decides whether a given file name is a directory.
    function isdir_c(fname) bind(c, name='fortyxima_filesys_isdir') result(res)
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: fname(*)
      integer(c_int) :: res
    end function isdir_c

    !> Decides whether a given file name is a symbolic link.
    function islink_c(fname) bind(c, name='fortyxima_filesys_islink') &
        & result(res)
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: fname(*)
      integer(c_int) :: res
    end function islink_c

    !> Checks, whether a given file exists.
    function file_exists_c(fname) &
        & bind(c, name='fortyxima_filesys_file_exists') result(res)
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: fname(*)
      integer(c_int) :: res
    end function file_exists_c

    !> Returns the size of a file.
    function filesize_c(fname) &
        & bind(c, name='fortyxima_filesys_filesize') result(res)
      import :: c_size_t, c_char
      character(kind=c_char), intent(in) :: fname(*)
      integer(c_size_t) :: res
    end function filesize_c

    !> Creates a directory with all possible permitions (except those in umask).
    function makedir_c(dirname) &
        & bind(c, name='fortyxima_filesys_makedir') result(res)
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: dirname(*)
      integer(c_int) :: res
    end function makedir_c

    !> Creates a directory with parents, no error if directory already exists.
    function makedir_parent_c(dirname) &
        & bind(c, name='fortyxima_filesys_makedir_parent') result(res)
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: dirname(*)
      integer(c_int) :: res
    end function makedir_parent_c

    !> Recursively deletes an entry in the file system.
    function rmtree_c(dirname) &
        & bind(c, name='fortyxima_filesys_rmtree') result(res)
      import :: c_int, c_char
      character(kind=c_char), intent(in) :: dirname(*)
      integer(c_int) :: res
    end function rmtree_c

    !> Returning working directory name with dynamic allocation as in glibc.
    function getcwd_c() bind(c, name='fortyxima_filesys_getcwd') result(res)
      import :: c_ptr
      type(c_ptr) :: res
    end function getcwd_c

    !> Frees a character string.
    subroutine freestring_c(ptr) bind(c, name='fortyxima_filesys_freestring')
      import :: c_ptr
      type(c_ptr) :: ptr
    end subroutine freestring_c

    !> Allocates a character string
    function copystring_c(origstr) &
        & bind(c, name='fortyxima_filesys_copystring') result(res)
      import :: c_char, c_ptr
      character(kind=c_char), intent(in) :: origstr(*)
      type(c_ptr) :: res
    end function copystring_c

    !> Calls the libc readlink function with dynamic memory allocation.
    function readlink_c(fname) bind(c, name='fortyxima_filesys_readlink') &
        & result(res)
      import :: c_char, c_ptr
      character(kind=c_char), intent(in) :: fname(*)
      type(c_ptr) :: res
    end function readlink_c
      
  end interface

end module fortyxima_filesys_libcwrapiface

!> \endcond
