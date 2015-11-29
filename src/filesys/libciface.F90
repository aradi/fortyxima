!> Wrappers for functionality in libc.
!! \cond HIDDEN
module fortyxima_filesys_libciface
  use, intrinsic :: iso_c_binding
  implicit none

  interface
    !> Unlinks a file.
    function libc_unlink(filename) bind(c, name='unlink') result(res)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: filename(*)
      integer(c_int) :: res
    end function libc_unlink

    !> Removes an empty directory.
    function libc_rmdir(filename) bind(c, name='rmdir') result(res)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: filename(*)
      integer(c_int) :: res
    end function libc_rmdir

    !> Removes a file or an empty directory.
    function libc_remove(filename) bind(c, name='remove') result(res)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: filename(*)
      integer(c_int) :: res
    end function libc_remove

    !> Renames a file.
    function libc_rename(oldname, newname) bind(c, name='rename') &
        & result(res)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: oldname(*), newname(*)
      integer(c_int) :: res
    end function libc_rename

    !> Opens a descriptor for a given directory.
    function libc_opendir(dirname) bind(c, name='opendir') result(res)
      import :: c_char, c_ptr
      character(kind=c_char), intent(in) :: dirname(*)
      type(c_ptr) :: res
    end function libc_opendir

    !> Closes a directory descriptor.
    subroutine libc_closedir(dirptr) bind(c, name='closedir')
      import :: c_ptr
      type(c_ptr), value :: dirptr
    end subroutine libc_closedir

    !> Reads the next entry from a directory.
    function libc_readdir(dp) bind(c, name='readdir') result(res)
      import :: c_ptr
      type(c_ptr), value :: dp
      type(c_ptr) :: res
    end function libc_readdir

    !> Returns the length of a null terminated string.
    function libc_strlen(pstr) bind(c, name='strlen') result(res)
      import :: c_ptr, c_size_t
      type(c_ptr), value :: pstr
      integer(c_size_t) :: res
    end function libc_strlen

    !> Changes to given directory.
    function libc_chdir(filename) bind(c, name='chdir') result(res)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: filename(*)
      integer(c_int) :: res
    end function libc_chdir

    !> Creates a hard link.
    function libc_link(oldname, newname) bind(c, name='link') &
        & result(res)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: oldname(*), newname(*)
      integer(c_int) :: res
    end function libc_link

    !> Creates a symbolic link.
    function libc_symlink(oldname, newname) bind(c, name='symlink') &
        & result(res)
      import :: c_char, c_int
      character(kind=c_char), intent(in) :: oldname(*), newname(*)
      integer(c_int) :: res
    end function libc_symlink

    !> Returns the real (canonized) path name.
    function libc_realpath(name, resolved) bind(c, name='realpath') &
        & result(res)
      import :: c_ptr
      type(c_ptr), value :: name, resolved
      type(c_ptr) :: res
    end function libc_realpath
  end interface

end module fortyxima_filesys_libciface

!> \endcond
