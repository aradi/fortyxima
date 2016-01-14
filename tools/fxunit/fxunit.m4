__silent_m4_begin{}m4_dnl

m4_define({__ASSERT}, {_fsplit(
block
  logical :: success
  success = {$1}
  call this%reportTestResult(success, "m4___file__", m4___line__, "{$1}")
  if (.not. success) then
    return
  end if
end block{}m4_dnl
)})


m4_define({_ASSERT}, {__ASSERT({this%isTrue($*)})})

m4_define({_ASSERT_TRUE}, {__ASSERT({this%isTrue($*)})})

m4_define({_ASSERT_FALSE}, {__ASSERT({this%isFalse($*)})})

__silent_m4_end{}m4_dnl
