#!/usr/bin/env python
from __future__ import print_function
import argparse
import re

RE_FLAGS = re.IGNORECASE | re.MULTILINE

MODULE_PATTERN = re.compile(
    r'(?:^|;)\s*module(?!\s+procedure)\s+(\w+)', RE_FLAGS)

END_MODULE_PATTERN = re.compile(
    r'(?:^|;)\s*end\s+module\s*(\w*)?', RE_FLAGS)

TYPE_PATTERN = re.compile(
    r'(?:^|;)\s*type(?:\s*|,\s*extends\(\w+\)\s*)::\s*(\w+)', RE_FLAGS)

SUBROUTINE_PATTERN = re.compile(
    r'(?:^|;)\s*subroutine\s+(test\w+)\(\s*(\w+)\s*\)', RE_FLAGS)

END_SUBROUTINE_PATTERN = re.compile(
    r'(?:^|;)\s*end\s+subroutine\s*(\w*)', RE_FLAGS)

DUMMY_ARG_PATTERN = re.compile(
    r'(?:^|;)\s*class\((\w+)\)[^:]*::\s*(\w+)', RE_FLAGS)


def get_test_methods(txt):
    testmethods = []
    for mod_match in MODULE_PATTERN.finditer(txt):
        modname = mod_match.group(1).lower()
        modstart = mod_match.end()
        endmod_match = END_MODULE_PATTERN.search(txt, mod_match.end())
        if not endmod_match:
            break
        modend = endmod_match.start()
        
        types = set([ s.lower() 
                      for s in TYPE_PATTERN.findall(txt, modstart, modend) ])

        for sub_match in SUBROUTINE_PATTERN.finditer(txt, modstart, modend):
            substart = sub_match.end()
            endsub_match = END_SUBROUTINE_PATTERN.search(txt, substart)
            if endsub_match is None:
                break
            subend = endsub_match.start()
            if subend > modend:
                break
            subname = sub_match.group(1).lower()
            subarg = sub_match.group(2).lower()
            
            iters = DUMMY_ARG_PATTERN.finditer(txt, substart, subend)
            for dummyarg_match in iters:
                classname = dummyarg_match.group(1).lower()
                argname = dummyarg_match.group(2).lower()
                if argname == subarg and classname in types:
                    testmethods.append(( modname, classname, subname ))
    return testmethods
    

def generate_includes(testmethods):
    modules = {}
    classes = {}
    use_lines = []
    instance_lines = []
    #dispatch_lines []
    for modname, classname, subname in testmethods:
        modname = modname.lower()
        classname = classname.lower()
        if not modname in modules:
            modules[modname] = []
        classes[classname.lower()] = classname + "Inst"
        
    

#if __name__ == "__main__":
    #main()
txt = '''module filesys
  use fortyxima_unittest
  use fortyxima_filesys
  implicit none

  type, extends(TestCase) :: Quick
  contains
    procedure :: testFileSize
  end type Quick

contains

  subroutine testFileSize(this)
    class(Quick), intent(inout) :: this

    print *, "TestFileSize"

  end subroutine testFileSize

  
end module filesys
'''

print(get_test_methods(txt))
