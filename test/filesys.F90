m4_include({fxunit.m4})
  
module filesys
  use, intrinsic :: iso_c_binding, only : c_char
  use fortyxima_unittest
  use fortyxima_filesys
  implicit none

  type, extends(TestCase) :: MyTest
  contains
    procedure :: setUp
    procedure :: tearDown
    procedure :: test_removeFile
    procedure :: test_dirManip
    procedure :: test_dirManipRecursive
    procedure :: test_remove
    procedure :: test_renameFile
    procedure :: test_renameDir
    procedure :: test_symlink
    procedure :: test_fileSize
    procedure :: test_directoryList
    procedure :: test_getWorkingDir
    procedure :: test_realPath
    procedure :: test_link
  end type MyTest

contains

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!  Initialization routines
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine setUp(this, name)
    class(MyTest), intent(inout) :: this
    character(*), intent(in) :: name

    call this%TestCase%setUp(name)
    if (isDir(name)) then
      call removeDir(name, children=.true.)
    end if
    call makeDir(name)
    call changeDir(name)

  end subroutine setUp


  subroutine tearDown(this)
    class(MyTest), intent(inout) :: this

    call changeDir('../')
    if (isDir(this%name)) then
      call removeDir(this%name, children=.true.)
    end if
    call this%TestCase%tearDown()

  end subroutine tearDown


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!  Test routines
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  subroutine test_removeFile(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: fileName = 'test.dat'
    integer :: error

    call createDummyFile(fileName)
    _ASSERT(fileExists(fileName))
    call removeFile(fileName, error)
    _ASSERT(error == 0)
    _ASSERT_FALSE(fileExists(fileName))
    call removeFile(fileName, error)
    _ASSERT(error /= 0)
    
  end subroutine test_removeFile


  subroutine test_dirManip(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: dirName = 'testdir'
    integer :: error

    call makeDir(dirName, error=error)
    _ASSERT(error == 0)
    _ASSERT(isDir(dirName))
    call removeDir(dirName, error=error)
    _ASSERT(error == 0)
    _ASSERT_FALSE(isDir(dirName))

  end subroutine test_dirManip


  subroutine test_dirManipRecursive(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: dirName = 'dir'
    character(*), parameter :: subdirName = 'subdir'
    integer :: error

    call makeDir(dirName // '/' // subdirName, error=error)
    _ASSERT(error /= 0)
    _ASSERT(.not. isDir(dirName))
    call makeDir(dirName // '/' // subdirName, parents=.true.)
    _ASSERT(isDir(dirName))
    _ASSERT(isDir(dirName // '/' // subdirName))
    call removeDir(dirName, error=error)
    _ASSERT(error /= 0)
    _ASSERT(isDir(dirName))
    call removeDir(dirName, children=.true.)
    _ASSERT(.not. isDir(dirName))

  end subroutine test_dirManipRecursive


  subroutine test_remove(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: fileName = 'test.dat'
    character(*), parameter :: dirName = 'mydir'
    character(100) :: fpath
    integer :: error

    call makeDir(dirName)
    fpath = dirName // '/' // fileName
    call createDummyFile(fpath)
    _ASSERT(fileExists(fpath))
    call remove(dirName, error=error)
    _ASSERT(error /= 0)
    _ASSERT(fileExists(fpath))
    call remove(fpath)
    _ASSERT_FALSE(fileExists(fileName))
    call remove(dirName)
    _ASSERT_FALSE(isDir(dirName))

  end subroutine test_remove


  subroutine test_renameFile(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: fileName = 'test.dat'
    character(*), parameter :: fileName2 = 'test.dat.new'

    call createDummyFile(fileName)
    _ASSERT(fileExists(fileName))
    call rename(fileName, fileName2)
    _ASSERT(fileExists(fileName2))
    _ASSERT_FALSE(fileExists(fileName))

  end subroutine test_renameFile


  subroutine test_renameDir(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: dirName = 'testdir'
    character(*), parameter :: dirName2 = 'testdir.new'

    call makeDir(dirName)
    _ASSERT(isDir(dirName))
    call rename(dirName, dirName2)
    _ASSERT(isDir(dirName2))
    _ASSERT_FALSE(isDir(dirName))

  end subroutine test_renameDir


  subroutine test_symlink(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: fileName = 'test.dat'
    character(*), parameter :: fileName2 = 'test2.dat'
    character(:), allocatable :: resolved

    call createDummyFile(fileName)
    _ASSERT(.not. isLink(fileName))
    call symlink(fileName, fileName2)
    _ASSERT(fileExists(fileName2))
    _ASSERT(isLink(fileName2))
    resolved = resolveLink(fileName2)
    _ASSERT(resolved == fileName)

  end subroutine test_symlink


  subroutine test_fileSize(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: fileName = 'test.dat'
    integer, parameter :: fileSize0 = 20

    call createDummyFile(fileName, fileSize=fileSize0)
    _ASSERT(fileSize(fileName) == fileSize0)

  end subroutine test_fileSize


  subroutine test_directoryList(this)
    class(MyTest), intent(inout) :: this

    integer, parameter :: nFiles = 4
    character(*), parameter :: fileNames(nFiles) = &
        & [ character(20) :: 'apple', 'banana', 'cherry', 'date' ]
    type(DirDesc) :: dir
    logical :: done(nFiles), match(nFiles)
    character(:), allocatable :: fileName
    integer :: iFile

    do iFile = 1, nFiles
      call createDummyFile(fileNames(iFile))
    end do
    done(:) = .false.
    call openDir('./', dir)
    fileName = dir%getNextEntry()
    do while(len(fileName) > 0)
      match(:) = (fileNames == fileName)
      _ASSERT(count(match) == 1)
      _ASSERT(count(match .and. done) == 0)
      done(:) = done .or. match
      fileName = dir%getNextEntry()
    end do
    _ASSERT(count(done) == nFiles)

  end subroutine test_directoryList


  subroutine test_getWorkingDir(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: dirName = 'mydir'
    character(*), parameter :: subdirName = 'mysubdir'
    character(:), allocatable :: dir1, dir2

    call makeDir(dirname // '/' // subdirName, parents=.true.)
    dir1 = getWorkingDir()
    call changeDir(dirname // '/' // subdirName)
    dir2 = getWorkingDir()
    _ASSERT(dir2 == dir1 // '/' // dirName // '/' // subdirName)
    call changeDir('../')
    dir2 = getWorkingDir()
    _ASSERT(dir2 == dir1 // '/' // dirName)
    call changeDir('../')
    dir2 = getWorkingDir()
    _ASSERT(dir2 == dir1)

  end subroutine test_getWorkingDir
      

  subroutine test_realPath(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: dirName = 'mydir'
    character(*), parameter :: subdirName = 'mysubdir'
    character(:), allocatable :: rpath0, rpath1, dir1

    rpath0 = realPath('./')
    dir1 = dirname // '/' // subdirName
    rpath1 = realPath(dir1)
    _ASSERT(len(rpath1) == 0)
    call makeDir(dir1, parents=.true.)
    rpath1 = realPath(dir1)
    _ASSERT(rpath1 == rpath0 // '/' // dirname // '/' // subdirName)

  end subroutine test_realPath


  subroutine test_link(this)
    class(MyTest), intent(inout) :: this

    character(*), parameter :: file1 = 'test.dat', file2 = 'test2.dat'
    character, allocatable :: buffer1(:), buffer2(:)
    integer :: error

    call createDummyFile(file1)
    call link(file1, file1, error=error)
    _ASSERT(error /= 0)
    call link(file1, file2)
    _ASSERT(fileSize(file1) == fileSize(file2))
    allocate(buffer1(fileSize(file1)))
    allocate(buffer2(fileSize(file2)))
    call readFileContent(file1, buffer1)
    call readFileContent(file2, buffer2)
    _ASSERT(all(buffer1 == buffer2))

  end subroutine test_link


  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!  Helper routines
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  subroutine createDummyFile(fileName, fileSize)
    character(*), intent(in) :: fileName
    integer, intent(in), optional :: fileSize

    integer :: fileSize0
    integer :: ii

    if (present(fileSize)) then
      fileSize0 = fileSize
    else
      fileSize0 = 10
    end if

    open(12, file=fileName, access='stream', action='write', status='replace')
    do ii = 1, fileSize0
      write(12) char(48 + modulo(ii, 10), kind=c_char)
    end do
    close(12)

  end subroutine createDummyFile


  subroutine readFileContent(fileName, buffer)
    character(*), intent(in) :: fileName
    character, intent(out) :: buffer(:)

    open(13, file=fileName, access='stream', action='read', status='old')
    read(13) buffer
    close(13)

  end subroutine readFileContent
    
  
end module filesys
