module fortyxima_unittest_testcase
  implicit none

  type :: TestCase
    character(:), allocatable :: id
  contains
    procedure :: setUp
    procedure :: tearDown
  end type TestCase

contains

  subroutine setUp(this, id)
    class(TestCase), intent(inout) :: this
    character(*), intent(in), optional :: id

    if (present(id)) then
      this%id = id
    end if

  end subroutine setUp


  subroutine tearDown(this)
    class(TestCase), intent(inout) :: this

    continue

  end subroutine tearDown

  
end module fortyxima_unittest_testcase
