!> \mainpage Modern Fortran file system interface
!!
!! The open source library
!! [modFileSys](https://www.bitbucket.org/aradi/modfilesys) is designed to
!! provide modern Fortran (Fortran 2003) wrappers around the file system
!! interface of libc. With its help you can carry out those basic file system
!! operations you were always missing in Fortran.
!!
!! For more information see the following sources:
!! * [Online documentation](https://aradi.bitbucket.org/modfilesys/)
!!   for installation and usage of the library
!! * [API documentation](annotated.html) for the reference manual.
!! * [Project home page](https://www.bitbucket.org/aradi/modfilesys/)
!!   for the source code, bug tracker and further information on the project.

!> Collection of convenient wrapper routines around libc's file system
!! interface.
!!
!! \details You can acces the module by importing it via the \c use command:
!!
!!     use libmodfilesys_module
!!
!! The allocatable character variables used by the routines are of the kind
!! \c c_char.  When you invoke them, you can nevertheless use normal character
!! variables of the default kind, as they should be compatible with them. If
!! not, your compiler should refuse to compile the code anyway.
!!
!!     character(:), allocatable :: mypath
!!
!!     mypath = getcwd()
!!
module fortyxima_filesys
  use fortyxima_filesys_common
  use fortyxima_filesys_libciface
  use fortyxima_filesys_libcwrapiface
  implicit none
  private

  public :: dirdesc
  public :: unlink
  public :: rmdir
  public :: remove
  public :: rename
  public :: opendir
  public :: isdir
  public :: islink
  public :: filesize
  public :: file_exists
  public :: mkdir
  public :: getcwd
  public :: chdir
  public :: link
  public :: symlink
  public :: readlink
  public :: realpath

  
  !> Directory descriptor.
  type :: dirdesc
    private
    type(c_ptr) :: cptr = c_null_ptr
  contains
    !> Returns next entry in the directory.
    procedure :: next_filename => dirdesc_next_filename

    !! Destructs a directory descriptor.
    final :: dirdesc_destruct

  end type dirdesc


contains

  !> Returns the name of the current working directory.
  !!
  !! \return Name of the current working directory or the empty string if
  !!     any error occured.
  !!
  !! \details Example:
  !!
  !!     write(*,*) "Current working directory:", getcwd()
  !!
  function getcwd() result(res)
    character(:, kind=c_char), allocatable :: res

    type(c_ptr) :: pstr

    pstr = getcwd_c()
    if (c_associated(pstr)) then
      call cptr_f_string(pstr, res, dealloc=.true.)
    else
      res = ""
    end if

  end function getcwd


  !> Changes the directory.
  !!
  !! \param fname  Name of the new directory.
  !! \param error  Error value of the libc chdir function. If not present and
  !!     different from zero, the routine stops.
  !!
  !! \details Example:
  !!
  !!     integer :: error
  !!
  !!     call chdir("newdir", error=error)   ! with explicit error handling
  !!
  subroutine chdir(fname, error)
    character(*, kind=c_char), intent(in) :: fname
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_chdir(f_c_string(fname))
    call handle_errorcode(error0, "Call 'libc_chdir' in 'chdir'", error)

  end subroutine chdir


  !> Creates a directory (with the default permission rights).
  !!
  !! \param dirname  Name of the directory to create.
  !! \param parents  Whether parents should be created if needed. Setting it to
  !!     .true. ommits error warning if directory already exists.
  !! \param error  Error value. If not present and different from zero,
  !!     the routine stops.
  !!
  !! \details Example:
  !!
  !!     integer :: error
  !!
  !!     call mkdir("./mydir/test1/test2", parents=.true.)
  !!     call mkdir("mydir")               ! parent directory must exist
  !!     call mkdir("mydir", error=error)  ! explicit error handling
  !!
  subroutine mkdir(dirname, parents, error)
    character(*, kind=c_char), intent(in) :: dirname
    logical, intent(in), optional :: parents
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0
    logical :: parents0

    if (present(parents)) then
      parents0 = parents
    else
      parents0 = .false.
    end if
    if (parents0) then
      error0 = makedir_parent_c(f_c_string(dirname))
      call handle_errorcode(error0, "Call 'makedir_parent_c' in mkdir",&
          & error)
    else
      error0 = makedir_c(f_c_string(dirname))
      call handle_errorcode(error0, "Call 'makedir_c' in mkdir", error)
    end if

  end subroutine mkdir


  !> Removes an empty directory.
  !!
  !! \param filename  Name of the directory.
  !! \param children  If set to yes, the directory may contain files or
  !!     directories, which will be recursively deleted.
  !! \param error  Error value of the libc rmdir function. If not present and
  !!     different from zero, the program stops.
  !!
  !! \details Example:
  !!
  !!     integer :: error
  !!
  !!     call rmdir("test")              ! Stops, if directory can't be deleted.
  !!     call rmdir("test", error=error) ! error =/ 0 signalizes failure
  !!     call rmdir("test", children=.true.)  ! Recursive delete
  !!
  subroutine rmdir(filename, children, error)
    character(*,kind=c_char), intent(in) :: filename
    logical, intent(in), optional :: children
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0
    logical :: children0

    if (present(children)) then
      children0 = children
    else
      children0 = .false.
    end if
    if (children0) then
      error0 = rmtree_c(f_c_string(filename))
      call handle_errorcode(error0, "Call 'rmtree_c' in 'rmdir'", error)
    else
      error0 = libc_rmdir(f_c_string(filename))
      call handle_errorcode(error0, "Call 'libc_rmdir' in 'rmdir'", &
          & error)
    end if

  end subroutine rmdir


  !> Unlinks (deletes) a file.
  !!
  !! \details Example:
  !!
  !!     integer :: error
  !!
  !!     call unlink("test")         ! Stops, if file can't be deleted
  !!     call unlink("test", error)  ! error =/ 0 signalizes failure
  !!
  !! \param filename  Name of the file.
  !! \param error  Error value of the libc unlink function. If not present and
  !!     different from zero, the routine stops.
  !!
  subroutine unlink(filename, error)
    character(*,kind=c_char), intent(in) :: filename
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_unlink(f_c_string(filename))
    call handle_errorcode(error0, "Call 'libc_unlink' in 'unlink'", &
        & error)
    
  end subroutine unlink


  !> Removes a file or an empty directory.
  !!
  !! \param filename  Name of the file.
  !! \param error  Error value of the libc remove function. If not present and
  !!     different from zero, the routine stops.
  !!
  !! \details Example:
  !!
  !!     integer :: error
  !!
  !!     call remove("test")     ! Stops, if file or directory can't be deleted.
  !!     call remove("test", error)  ! error =/ 0 signalizes failure
  !!
  subroutine remove(filename, error)
    character(*,kind=c_char), intent(in) :: filename
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_remove(f_c_string(filename))
    call handle_errorcode(error0, "Call 'libc_remove' in 'remove'", &
        & error)

  end subroutine remove

  
  !> Renames a file or a directory.
  !!
  !! \param oldname  Old file name.
  !! \param newname  New file name.
  !! \param error  Error value of the libc rename function. If not present and
  !!     different from zero, the routine stops.
  !!
  !! \details Example:
  !!
  !!     integer :: error
  !!
  !!     call rename("test1.dat", "test2.dat")    ! Stops at failure
  !!     call rename("test1.dat", "test2.dat", error)  ! sets error =/ 0 at failure
  !!
  subroutine rename(oldname, newname, error)
    character(*,kind=c_char), intent(in) :: oldname, newname
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_rename(f_c_string(oldname), f_c_string(newname))
    call handle_errorcode(error0, "Call 'libc_rename' in 'rename'", &
        & error)

  end subroutine rename


  !> Creates a hard link.
  !!
  !! \param oldname  Name of the existing file.
  !! \param newname  Name of the new link.
  !! \param error  Error value of the libc link function. If not present and
  !!     different from zero, the routine stops.
  !!
  !! \details Example:
  !!
  !!     call link("oldfile", "aliasfile")
  !!
  subroutine link(oldname, newname, error)
    character(*, kind=c_char), intent(in) :: oldname, newname
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_link(f_c_string(oldname), f_c_string(newname))
    call handle_errorcode(error0, "Call 'libc_link' in 'link'", error)

  end subroutine link


  !> Creates a symbolic link.
  !!
  !! \param oldname  Name of the existing file.
  !! \param newname  Name of the new link.
  !! \param error  Error value of the libc symlink function. If not present and
  !!     different from zero, the routine stops.
  !!
  !! \details Example:
  !!
  !!     call symlink("oldfile", "aliasfile")
  !!
  subroutine symlink(oldname, newname, error)
    character(*, kind=c_char), intent(in) :: oldname, newname
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_symlink(f_c_string(oldname), f_c_string(newname))
    call handle_errorcode(error0, "Call 'libc_symlink' in 'symlink'", &
        & error)

  end subroutine symlink


  !> Checks whether a file with given name exists.
  !!
  !! \param fname  File name.
  !! \return True if file exists, False otherwise.
  !!
  !! \details Example:
  !!
  !!      if (file_exists("/tmp/testfile")) then
  !!         ! do something with that file
  !!      end if
  !!
  function file_exists(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    logical :: res

    res = (file_exists_c(f_c_string(fname)) /= 0)

  end function file_exists

  
  !> Checks whether a file with a given name exists and is a directory.
  !!
  !! \details Example:
  !!
  !!     if (isdir("somefile")) then
  !!       ! do something with the existing directory
  !!     end if
  !!
  !! \param fname  File name.
  !! \return True if file exists and is a directory, False otherwise.
  !!
  function isdir(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    logical :: res

    integer(c_int) :: status

    status = isdir_c(f_c_string(fname))
    res = (status /= 0)
    
  end function isdir


  !> Checks whether a file with a given name exists and is a symbolic link.
  !!
  !! \param fname  File name.
  !! \return True if file exists and is a symlink, False otherwise.
  !!
  !! \details Example:
  !!
  !!     if (islink("somefile")) then
  !!       write(*,*) "Link points to: ", readlink("somefile")
  !!     end if
  !!
  function islink(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    logical :: res

    integer(c_int) :: status

    status = islink_c(f_c_string(fname))
    res = (status /= 0)
    
  end function islink


  !> Resolves a link.
  !!
  !! \param fname  Name of the file to resolve.
  !! \return  Resolved link name or empty string if any error occured.
  !!
  !! \details Example: see \ref islink().
  !!
  function readlink(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    character(:, kind=c_char), allocatable :: res

    type(c_ptr) :: ptr

    ptr = readlink_c(f_c_string(fname))
    if (c_associated(ptr)) then
      call cptr_f_string(ptr, res, dealloc=.true.)
    else
      res = ""
    end if
    
  end function readlink


  !> Returns the real (canonized) name of a path.
  !!
  !! \param fname  Path to resolve.
  !! \return Real path name or empty string if any error occured.
  !!
  !! \details Example:
  !!
  !!     write(*,*) "Full canonized path name of './'", realpath("./")
  !!
  function realpath(fname) result(res)
    character(*, kind=c_char), intent(in) ::fname
    character(:, kind=c_char), allocatable  :: res

    type(c_ptr) :: cname, cresolved, rpath

    rpath = c_null_ptr
    cname = f_cptr_string(fname)
    if (c_associated(cname)) then
      cresolved = c_null_ptr
      rpath = libc_realpath(cname, cresolved)
      call freestring_c(cname)
    end if
    if (c_associated(rpath)) then
      call cptr_f_string(rpath, res, dealloc=.true.)
    else
      res = ""
    end if

  end function realpath
    

  !> Returns the size of a given file.
  !!
  !! \param fname  File name.
  !! \return  Size of the file. If the file status could not be determined
  !!     -1 is returned. If the file size could not be converted to a fortran
  !!     compatible integer, -2 will be returned.
  !!
  !! \details Example:
  !!
  !!     write(*,*) "Size of the file 'test.dat': ", filesize("test.dat")
  !!
  function filesize(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    integer(c_size_t) :: res

    res = filesize_c(f_c_string(fname))

  end function filesize


  !> Returns a descriptor to a directory.
  !!
  !! \param dirname  Name of the directory.
  !! \param dirptr  Directory descriptor on return.
  !! \param error  Error value of the libc opendir function. If not present and
  !!     different from zero, the routine stops.
  !!
  !! \details Example (listing the current directory):
  !!
  !!     type(dirdesc) :: dir
  !!     character(:), allocatable :: path
  !!
  !!     call opendir("./", dir)
  !!     path = dir%next_filename()
  !!     do while (len(path) > 0)
  !!       write(*, "(A)") path
  !!       path = dir%next_filename()
  !!     end do
  !!
  subroutine opendir(dirname, dirptr, error)
    character(*, kind=c_char), intent(in) :: dirname
    type(dirdesc), intent(out) :: dirptr
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    dirptr%cptr = libc_opendir(f_c_string(dirname))
    if (c_associated(dirptr%cptr)) then
      error0 = 0
    else
      error0 = -1
    end if
    call handle_errorcode(error0, "Call 'libc_opendir' in 'opendir'", &
        & error)

  end subroutine opendir


  !> Returns the name of the next entry in a directory (without "." and "..").
  !!
  !! \param self  Directory descriptor.
  !! \return  Name of the next entry or empty string if error occured.
  !!
  !! \details Example: see \ref opendir().
  !!
  function dirdesc_next_filename(self) result(fname)
    class(dirdesc), intent(inout) :: self
    character(:, kind=c_char), allocatable :: fname

    type(c_ptr) :: cptr

    cptr = nextdirentry_name_c(self%cptr)
    if (c_associated(cptr)) then
      call cptr_f_string(cptr, fname, dealloc=.true.)
    else
      fname = ""
    end if

  end function dirdesc_next_filename

  
  !! Destructs a directory descriptor.
  !! \param self  Directory descriptor instance.
  subroutine dirdesc_destruct(self)
    type(dirdesc), intent(inout) :: self

    call libc_closedir(self%cptr)

  end subroutine dirdesc_destruct


end module fortyxima_filesys
