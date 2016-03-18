!> Contains wrappers around the file system interface of libc.
!!
module fortyxima_filesys
  use fortyxima_filesys_common
  use fortyxima_filesys_libciface
  use fortyxima_filesys_libcwrapiface
  implicit none
  private

  public :: DirDesc
  public :: removeFile
  public :: removeDir
  public :: remove
  public :: rename
  public :: openDir
  public :: closeDir
  public :: isDir
  public :: isLink
  public :: fileSize
  public :: fileExists
  public :: makeDir
  public :: getWorkingDir
  public :: changeDir
  public :: link
  public :: symlink
  public :: resolveLink
  public :: realPath
  public :: copyFile

  
  !> Directory descriptor.
  type :: DirDesc
    private
    type(c_ptr) :: cptr = c_null_ptr
  contains
    !> Returns next entry in the directory.
    procedure :: getNextEntry => DirDesc_getNextEntry

  #! Workaround: Gfortran has problems with destructors (as of version 5.2)
  #:if not defined('COMP_GFORTRAN')
    ! Destructs a directory descriptor.
    final :: DirDesc_destruct
  #:endif

  end type DirDesc


contains

  !> Returns the name of the current working directory.
  !!
  !! \return Name of the current working directory or the empty string if
  !!     any error occured.
  !!
  !! \details Example:
  !!
  !!     write(*,*) "Current working directory:", getWorkingDir()
  !!
  function getWorkingDir() result(res)
    character(:, kind=c_char), allocatable :: res

    type(c_ptr) :: pstr

    pstr = getcwd_c()
    if (c_associated(pstr)) then
      call cptr_f_string(pstr, res, dealloc=.true.)
    else
      res = ""
    end if

  end function getWorkingDir


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
  !!     call changeDir("newdir", error=error)   ! with explicit error handling
  !!
  subroutine changeDir(fname, error)
    character(*, kind=c_char), intent(in) :: fname
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_chdir(f_c_string(fname))
    call handle_errorcode(error0, "Call 'libc_chdir' in 'changeDir'", error)

  end subroutine changeDir


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
  !!     call makeDir("./mydir/test1/test2", parents=.true.)
  !!     call makeDir("mydir")               ! parent directory must exist
  !!     call makeDir("mydir", error=error)  ! explicit error handling
  !!
  subroutine makeDir(dirname, parents, error)
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
      call handle_errorcode(error0, "Call 'makedir_parent_c' in makeDir", error)
    else
      error0 = makedir_c(f_c_string(dirname))
      call handle_errorcode(error0, "Call 'makedir_c' in makeDir", error)
    end if

  end subroutine makeDir


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
  !!     call removeDir("test")  ! Stops, if directory can't be deleted.
  !!     call removeDir("test", error=error) ! error =/ 0 signalizes failure
  !!     call removeDir("test", children=.true.)  ! Recursive delete
  !!
  subroutine removeDir(filename, children, error)
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
      call handle_errorcode(error0, "Call 'rmtree_c' in 'removeDir'", error)
    else
      error0 = libc_rmdir(f_c_string(filename))
      call handle_errorcode(error0, "Call 'libc_rmdir' in 'removeDir'", error)
    end if

  end subroutine removeDir


  !> Removes a file.
  !!
  !! \details Example:
  !!
  !!     integer :: error
  !!
  !!     call removeFile("test")         ! Stops, if file can't be deleted
  !!     call removeFile("test", error)  ! error =/ 0 signalizes failure
  !!
  !! \param filename  Name of the file.
  !! \param error  Error value of the libc unlink function. If not present and
  !!     different from zero, the routine stops.
  !!
  subroutine removeFile(filename, error)
    character(*,kind=c_char), intent(in) :: filename
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    error0 = libc_unlink(f_c_string(filename))
    call handle_errorcode(error0, "Call 'libc_unlink' in 'removeFile'", error)
    
  end subroutine removeFile


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
    call handle_errorcode(error0, "Call 'libc_remove' in 'remove'", error)

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
  !!      if (fileExists("/tmp/testfile")) then
  !!         ! do something with that file
  !!      end if
  !!
  function fileExists(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    logical :: res

    res = (file_exists_c(f_c_string(fname)) /= 0)

  end function fileExists

  
  !> Checks whether a file with a given name exists and is a directory.
  !!
  !! \details Example:
  !!
  !!     if (isDir("somefile")) then
  !!       ! do something with the existing directory
  !!     end if
  !!
  !! \param fname  File name.
  !! \return True if file exists and is a directory, False otherwise.
  !!
  function isDir(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    logical :: res

    integer(c_int) :: status

    status = isdir_c(f_c_string(fname))
    res = (status /= 0)
    
  end function isDir


  !> Checks whether a file with a given name exists and is a symbolic link.
  !!
  !! \param fname  File name.
  !! \return True if file exists and is a symlink, False otherwise.
  !!
  !! \details Example:
  !!
  !!     if (isLink("somefile")) then
  !!       write(*,*) "Link points to: ", resolveLink("somefile")
  !!     end if
  !!
  function isLink(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    logical :: res

    integer(c_int) :: status

    status = islink_c(f_c_string(fname))
    res = (status /= 0)
    
  end function isLink


  !> Resolves a link.
  !!
  !! \param fname  Name of the file to resolve.
  !! \return  Resolved link name or empty string if any error occured.
  !!
  !! \details Example: see \ref isLink().
  !!
  function resolveLink(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    character(:, kind=c_char), allocatable :: res

    type(c_ptr) :: ptr

    ptr = readlink_c(f_c_string(fname))
    if (c_associated(ptr)) then
      call cptr_f_string(ptr, res, dealloc=.true.)
    else
      res = ""
    end if
    
  end function resolveLink


  !> Returns the real (canonized) name of a path.
  !!
  !! \param fname  Path to resolve.
  !! \return Real path name or empty string if any error occured.
  !!
  !! \details Example:
  !!
  !!     write(*,*) "Full canonized path name of './'", realPath("./")
  !!
  function realPath(fname) result(res)
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

  end function realPath
    

  !> Returns the size of a given file.
  !!
  !! \param fname  File name.
  !! \return  Size of the file. If the file status could not be determined
  !!     -1 is returned. If the file size could not be converted to a fortran
  !!     compatible integer, -2 will be returned.
  !!
  !! \details Example:
  !!
  !!     write(*,*) "Size of the file 'test.dat': ", fileSize("test.dat")
  !!
  function fileSize(fname) result(res)
    character(*, kind=c_char), intent(in) :: fname
    integer(c_size_t) :: res

    res = filesize_c(f_c_string(fname))

  end function fileSize


  !> Returns a descriptor to a directory.
  !!
  !! \param dirname  Name of the directory.
  !! \param dirptr  Directory descriptor on return.
  !! \param error  Error value of the libc opendir function. If not present and
  !!     different from zero, the routine stops.
  !!
  !! \details Example (listing the current directory):
  !!
  !!     type(DirDesc) :: dir
  !!     character(:), allocatable :: path
  !!
  !!     call openDir("./", dir)
  !!     path = dir%nextEntry()
  !!     do while (len(path) > 0)
  !!       write(*, "(A)") path
  !!       path = dir%nextEntry()
  !!     end do
  !!
  !!     ! closeDir call only needed if compiled with GFortran (bug 68778)
  !!     ! Otherwise dir will be automatically closed when going out of scope.
  !!     call closeDir(dir)
  !!
  subroutine openDir(dirname, dirptr, error)
    character(*, kind=c_char), intent(in) :: dirname
    type(DirDesc), intent(out) :: dirptr
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0

    dirptr%cptr = libc_opendir(f_c_string(dirname))
    if (c_associated(dirptr%cptr)) then
      error0 = 0
    else
      error0 = -1
    end if
    call handle_errorcode(error0, "Call 'libc_opendir' in 'openDir'", error)

  end subroutine openDir


  !> Frees the directory descriptor and deallocates memory.
  !!
  !! \param dirptr  Descriptor to be freed.
  !!
  !! \note Usually you should not call this function as the structure destructor
  !!     does it automatically for you when the descriptor goes out of
  !!     scope. However, for GFortran the destructor is disabled as it leads to
  !!     crashing code due to bug 68778. In that case, you can call this
  !!     function explicitely after having finished all directory operations, in
  !!     order to avoid memory leaks.
  !!
  subroutine closeDir(dirptr)
    type(DirDesc), intent(inout) :: dirptr

    call DirDesc_destruct(dirptr)

  end subroutine closeDir


  !> Returns the name of the next entry in a directory (without "." and "..").
  !!
  !! \param this  Directory descriptor.
  !! \return  Name of the next entry or empty string if error occured.
  !!
  !! \details Example: see \ref openDir().
  !!
  function DirDesc_getNextEntry(this) result(fname)
    class(DirDesc), intent(inout) :: this
    character(:, kind=c_char), allocatable :: fname

    type(c_ptr) :: cptr

    cptr = nextdirentry_name_c(this%cptr)
    if (c_associated(cptr)) then
      call cptr_f_string(cptr, fname, dealloc=.true.)
    else
      fname = ""
    end if

  end function DirDesc_getNextEntry

  
  !! Destructs a directory descriptor.
  !! \param this  Directory descriptor instance.
  subroutine DirDesc_destruct(this)
    type(DirDesc), intent(inout) :: this

    if (c_associated(this%cptr)) then
      call libc_closedir(this%cptr)
      this%cptr = c_null_ptr
    end if

  end subroutine DirDesc_destruct


  !> Creates a new file with the content of an other one.
  !!
  !! \details Example:
  !!
  !!      call copyFile("/tmp/file1", "/tmp/file2")
  !!
  !! \param orig  File to be copied.
  !! \param copy  Copy file to be created (or replaced if already existing).
  !! \param bufferSize  Buffer size to use during copy (default: 64 kB).
  !! \param error  Error code of the operation. If not present and
  !!     different from zero, the routine stops.
  !!
  subroutine copyFile(orig, copy, bufferSize, error)
    character(*), intent(in) :: orig, copy
    integer(c_int), intent(in), optional :: bufferSize
    integer(c_int), intent(out), optional :: error

    integer(c_int) :: error0, bufferSize0
    integer(c_int), parameter :: defaultBufferSize = 64 * 1024

    if (present(bufferSize)) then
      bufferSize0 = bufferSize
    else
      bufferSize0 = defaultBufferSize
    end if
    if (.not. fileExists(orig)) then
      error0 = 1
      call handle_errorcode(error0, "copyFile: missing source file", error)
    end if
    error0 = copyfile_c(f_c_string(orig), f_c_string(copy), bufferSize0)
    call handle_errorcode(error0, "copyfile_c in copyFile", error)

  end subroutine copyFile


end module fortyxima_filesys
