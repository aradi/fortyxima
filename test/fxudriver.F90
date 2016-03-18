program fxunit_driver_atomic
  use fortyxima_unittest
  implicit none

  character(:), allocatable :: testName
  integer :: argLen

  call get_command_argument(1, length=argLen)
  allocate(character(argLen) :: testName)
  call get_command_argument(1, testName)

  select case (trim(testName))
case ("filesys_removefile")
  call filesys_removefile
case ("filesys_dirmanip")
  call filesys_dirmanip
case ("filesys_dirmaniprecursive")
  call filesys_dirmaniprecursive
case ("filesys_remove")
  call filesys_remove
case ("filesys_renamefile")
  call filesys_renamefile
case ("filesys_renamedir")
  call filesys_renamedir
case ("filesys_symlink")
  call filesys_symlink
case ("filesys_filesize")
  call filesys_filesize
case ("filesys_directorylist")
  call filesys_directorylist
case ("filesys_getworkingdir")
  call filesys_getworkingdir
case ("filesys_realpath")
  call filesys_realpath
case ("filesys_link")
  call filesys_link
case ("filesys_copyfile")
  call filesys_copyfile
  case default
    write(stderr, "(A,A,A)") "Invalid test name '", trim(testName), "'"
    error stop 1
  end select

contains

  subroutine handleTestResult(test)
    class(TestCase), intent(in) :: test

    if (test%status == TEST_FAILED) then
      write(stderr, "(A)") "Test failed!"
      write(stderr, "(A,1X,A)") "File:", test%file
      write(stderr, "(A,1X,I0)") "Line:", test%line
      write(stderr, "(A,1X,A)") "Test:", test%msg
      error stop 1
    end if

  end subroutine handleTestResult



subroutine filesys_removefile
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_removefile")
  call mytestInst%test_removefile()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_removefile


subroutine filesys_dirmanip
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_dirmanip")
  call mytestInst%test_dirmanip()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_dirmanip


subroutine filesys_dirmaniprecursive
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_dirmaniprecursive")
  call mytestInst%test_dirmaniprecursive()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_dirmaniprecursive


subroutine filesys_remove
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_remove")
  call mytestInst%test_remove()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_remove


subroutine filesys_renamefile
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_renamefile")
  call mytestInst%test_renamefile()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_renamefile


subroutine filesys_renamedir
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_renamedir")
  call mytestInst%test_renamedir()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_renamedir


subroutine filesys_symlink
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_symlink")
  call mytestInst%test_symlink()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_symlink


subroutine filesys_filesize
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_filesize")
  call mytestInst%test_filesize()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_filesize


subroutine filesys_directorylist
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_directorylist")
  call mytestInst%test_directorylist()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_directorylist


subroutine filesys_getworkingdir
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_getworkingdir")
  call mytestInst%test_getworkingdir()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_getworkingdir


subroutine filesys_realpath
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_realpath")
  call mytestInst%test_realpath()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_realpath


subroutine filesys_link
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_link")
  call mytestInst%test_link()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_link


subroutine filesys_copyfile
  use filesys, only : mytest
  type(mytest) :: mytestInst

  call mytestInst%setUp("filesys_copyfile")
  call mytestInst%test_copyfile()
  call mytestInst%tearDown()
  call handleTestResult(mytestInst)

end subroutine filesys_copyfile
  
end program fxunit_driver_atomic
