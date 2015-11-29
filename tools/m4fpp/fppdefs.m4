m4_dnl ************************************************************************
m4_dnl 
m4_dnl  M4 macros for preprocessing Fortran source files
m4_dnl
m4_dnl ************************************************************************
m4_dnl
m4_dnl NOTE: GNU m4 must be invoked with the -P prefix to process this file.
m4_dnl
m4_dnl ************************************************************************
m4_dnl Private part
m4_dnl ************************************************************************
m4_dnl
m4_changequote({,})m4_dnl
m4_dnl
m4_dnl Diverting M4 output to nowhere
m4_dnl
m4_define({__silent_m4_begin}, {m4_dnl
m4_pushdef({__file_prev_divnum}, m4_divnum)m4_dnl
m4_divert(-1)})m4_dnl
m4_dnl
__silent_m4_begin()m4_dnl


m4_dnl Diverting output back, where it was before the diversion
m4_dnl
m4_define({__silent_m4_end}, {m4_dnl
m4_divert(__file_prev_divnum)m4_dnl
m4_popdef({__file_prev_divnum})})


m4_dnl Marks the beginning of an if block.
m4_dnl
m4_define({__if}, {m4_dnl
m4_pushdef({__if_prev_divnum}, m4_divnum)m4_dnl
m4_pushdef({__if_cond}, m4_ifelse({$1}, 1, {true}, {false}))m4_dnl
m4_ifelse(__if_cond, {true}, {m4_divert(__if_prev_divnum)}, 
    {m4_divert(-1)})m4_dnl
})


m4_dnl Marks the else block.
m4_dnl
m4_define({__else}, {m4_dnl
m4_ifelse(__if_cond, {true}, {m4_divert(-1)}, 
    {m4_divert(__if_prev_divnum)})m4_dnl
})


m4_dnl Marks the end of an if block.
m4_dnl
m4_define({__endif}, {m4_dnl
m4_divert(__if_prev_divnum)m4_dnl
m4_popdef({__if_prev_divnum})m4_dnl
m4_popdef({__if_cond})m4_dnl
})


m4_dnl Splits a string into parts based on length.
m4_dnl
m4_dnl $1  String to split
m4_dnl $2  Maximal length of a line.
m4_dnl $3  String to use to mark the end of the splitted line.
m4_dnl $4  String to use to mark the beginning of the continuation line.
m4_dnl
m4_define({__split}, {__recursive_split($@, 0, m4_eval(m4_len({$1})))})


m4_dnl Recursive helper function for split.
m4_dnl
m4_dnl $1  String to split
m4_dnl $2  Maximal length of a line.
m4_dnl $3  String to use to mark the end of the splitted line.
m4_dnl $4  String to use to mark the beginning of the continuation line.
m4_dnl $5  At which position in the string we should start.
m4_dnl $6  At which position in the string we should stop.
m4_dnl 
m4_define({__recursive_split}, {m4_dnl
m4_substr({$1}, $5, $2){}m4_dnl
m4_ifelse(m4_eval($6 - $2 <= 0), 1, {}, {$3
$4{}$0({$1}, $2, {$3}, {$4}, m4_eval($5 + $2), m4_eval($6 - $2))})})


m4_dnl Invokes __split with settings for Fortran
m4_dnl
m4_define({__fsplit}, {__split({$1}, 74, {&}, {    &})})


m4_dnl Applies a macro command to each line of its argument
m4_dnl
m4_dnl $1  Macro to apply. It must expect one argument.
m4_dnl $2  Text to process. The macro will call $1 with each line of the
m4_dnl     text separately.
m4_dnl
m4_define({__apply_on_each_line}, {m4_patsubst({$2}, {^.*$}, {$1({\&})})})


m4_dnl Splits the lines of its argument the Fortran way.
m4_dnl
m4_dnl $1  Fortran source to split.
m4_dnl
m4_define({__fsplit_lines}, {__apply_on_each_line({__fsplit}, {$1})})


m4_dnl ************************************************************************
m4_dnl Exported commands
m4_dnl ************************************************************************


m4_dnl Defines the beginning of an ifdef region.
m4_dnl
m4_dnl Code in the region is only inserted when the M4 variable in the
m4_dnl argument is defined.
m4_dnl
m4_dnl $1  Variable to look for.
m4_dnl
m4_define({_ifdef}, {m4_dnl
__if(m4_ifdef({$1}, 1, 0))m4_dnl
})


m4_dnl Defines the beginning of an ifndef region.
m4_dnl
m4_dnl Code in the region is only inserted when the M4 variable in the
m4_dnl argument is not defined.
m4_dnl
m4_dnl $1  Variable to look for.
m4_dnl
m4_define({_ifndef}, {m4_dnl
__if(m4_ifdef({$1}, 0, 1))m4_dnl
})


m4_dnl Defines the beginning of an if region.
m4_dnl
m4_dnl Code in the region is only inserted when the M4 conditional expression 
m4_dnl in the argument evaluates true.
m4_dnl
m4_dnl $1  M4 conditional expression, which will be evaluated using
m4_dnl     M4s eval() marco.
m4_dnl
m4_define({_if}, {m4_dnl
__if(m4_eval($1))m4_dnl
})


m4_dnl Defines the end of the true branch and the beginning of the false branch.
m4_dnl
m4_define({_else}, {m4_dnl
__else{}m4_dnl
})


m4_dnl Defines the end of an if or ifdef construct.
m4_dnl
m4_define({_endif}, {m4_dnl
__endif{}m4_dnl
})


m4_dnl Splits the lines of the argument into Fortran continuation lines.
m4_dnl
m4_dnl $1  Fortran code to be split. Can also contain multiple lines, in
m4_dnl     that case splitting is made separately for every line.
m4_dnl
m4_define({_fsplit}, {__fsplit_lines({$1})})


m4_dnl Marks the beginning of a block with suppressed output of M4 to stdout.
m4_dnl
m4_define({_silent_m4_begin}, {__silent_m4_begin()})


m4_dnl Marks the end of a block with suppressed output of M4 to stdout.
m4_dnl
m4_define({_silent_m4_end}, {__silent_m4_end()})


m4_dnl Calls the assert subroutine, if condition is not matched.
m4_dnl
m4_dnl The called assert subroutine must be provided in the scope
m4_dnl where the macro is invoked. It has to have the following interface:
m4_dnl
m4_dnl   subroutine assert(msg, filename, linenr)
m4_dnl       character(*), intent(in) :: msg, filename
m4_dnl       integer, intent(in) :: linenr
m4_dnl   end subroutine assert
m4_dnl
m4_dnl $1  Fortran logical expression
m4_dnl
m4_define({_assert}, {m4_dnl
_if({_ASSERTS == 1})m4_dnl
_fsplit(_ASSERT_MACRO({($1)}, "m4___file__", m4___line__))m4_dnl
_endif{}m4_dnl
})


m4_dnl Marks the begin of a debug region, which is inserted if _DEBUG > 0.
m4_dnl
m4_define({_debug_begin}, {_if({_DEBUG > 0})})


m4_dnl Marks the end of a debug region, which is inserted if _DEBUG > 0.
m4_dnl
m4_define({_debug_end}, {_endif})


m4_dnl Inserts the argument into the code only, if _DEBUG > 0.
m4_dnl
m4_dnl $1  Fortran code to be inserted if in debug mode.
m4_dnl
m4_define({_debug}, {m4_dnl
_debug_begin{}{$1}_debug_end{}m4_dnl
})


m4_dnl Marks the begin of an assert related region, which is inserted only if
m4_dnl _ASSERTS = 1.
m4_dnl
m4_define({_assert_env_begin}, {_if({_ASSERTS == 1})})


m4_dnl Marks the end of a debug region, which is inserted if _DEBUG > 0.
m4_dnl
m4_define({_assert_env_end}, {_endif})


m4_dnl Inserts the argument into the code only, if _DEBUG > 0.
m4_dnl
m4_dnl $1  Fortran code to be inserted if in debug mode.
m4_dnl
m4_define({_assert_env}, {m4_dnl
_assert_env_begin{}{$1}_assert_env_end{}m4_dnl
})


m4_dnl Debug level set to zero, unless already explicitely defined
m4_dnl
m4_define({_DEBUG}, m4_ifdef({_DEBUG}, _DEBUG, 0))


m4_dnl Asserts are not included by default.
m4_dnl
m4_define({_ASSERTS}, m4_ifdef({_ASSERTS}, _ASSERTS, 0))


m4_dnl Default for the assert() call, should be replaced by the user
m4_dnl
m4_dnl $1  Fortran logical expression (enclosed in paranthesis)
m4_dnl $2  File name where assertion was placed (in quotes)
m4_dnl $3  Line number of assertion.
m4_dnl
m4_define({_ASSERT_MACRO}, {m4_dnl
if (!$1) then
  write(*,*) "ASSERTION FAILED"
  write(*,*) "File:"{,} $2
  write(*,*) "Line:"{,} $3
  stop -1
end if{}m4_dnl
})

m4_dnl Version number for the preprocessor.
m4_dnl
m4_define({_m4fpp_version}, {1.0})


__silent_m4_end()m4_dnl
