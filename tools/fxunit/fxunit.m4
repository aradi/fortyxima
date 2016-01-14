_SILENT_M4_BEGIN{}m4_dnl

m4_define({_ASSERT_BLOCK}, {_FSPLIT(
block
  logical :: success
  success = {$1}
  call this%reportTestResult(success, "m4___file__", m4___line__, "{$1}")
  if (.not. success) then
    return
  end if
end block{}m4_dnl
)})


m4_define({_ASSERT}, {_ASSERT_BLOCK({this%isTrue($*)})})

m4_define({_ASSERT_TRUE}, {_ASSERT_BLOCK({this%isTrue($*)})})

m4_define({_ASSERT_FALSE}, {_ASSERT_BLOCK({this%isFalse($*)})})

_SILENT_M4_END{}m4_dnl
