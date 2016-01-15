module fortyxima_unittest_testcase
  implicit none
  private

  public :: TestCase
  public :: TEST_NOT_RUN, TEST_SUCCEEDED, TEST_FAILED

  integer, parameter :: TEST_NOT_RUN = 0
  integer, parameter :: TEST_SUCCEEDED = 1
  integer, parameter :: TEST_FAILED = 2

  
  type :: TestCase
    character(:), allocatable :: name, file, msg
    integer :: line = -1
    integer :: status = TEST_NOT_RUN
  contains
    procedure :: setUp
    procedure :: tearDown
    procedure :: reportTestResult
    procedure :: isTrue
    procedure :: isFalse
  end type TestCase

contains

  subroutine setUp(this, name)
    class(TestCase), intent(inout) :: this
    character(*), intent(in) :: name

    this%name = name
    
  end subroutine setUp


  subroutine tearDown(this)
    class(TestCase), intent(inout) :: this

    continue

  end subroutine tearDown


  subroutine reportTestResult(this, success, file, line, msg)
    class(TestCase), intent(inout) :: this
    logical, intent(in) :: success
    character(*), intent(in) :: file
    integer, intent(in) :: line
    character(*), intent(in) :: msg

    if (success) then
      this%status = TEST_SUCCEEDED
    else
      this%status = TEST_FAILED
    end if
    this%file = file
    this%line = line
    this%msg = msg

  end subroutine reportTestResult

  
  function isTrue(this, cond) result(res)
    class(TestCase), intent(in) :: this
    logical, intent(in) :: cond
    logical :: res

    res = cond

  end function isTrue


  function isFalse(this, cond) result(res)
    class(TestCase), intent(in) :: this
    logical, intent(in) :: cond
    logical :: res

    res = .not. cond

  end function isFalse
  

end module fortyxima_unittest_testcase
