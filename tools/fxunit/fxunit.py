#!/usr/bin/env python
import argparse
import re

RE_FLAGS = re.IGNORECASE | re.MULTILINE

MODULE_PATTERN = re.compile(
    r'^\s*module\s+(\w+)\s*$', RE_FLAGS)

END_MODULE_PATTERN = re.compile(
    r'^\s*end\s+module\s*(\w*)?\s*$', RE_FLAGS)

TYPE_PATTERN = re.compile(
    r'^\s*type(?:\s*|,\s*extends\(\w+\)\s*)::\s*(\w+)\s*$', RE_FLAGS)

END_TYPE_PATTERN = re.compile(
    r'^\s*end\s+type\s*(\w*)\s*$', RE_FLAGS)

PROCEDURE_PATTERN = re.compile(
    r'^\s*procedure\s*(?:,\s*pass\s*)?::\s*(test\w+)(?:\s*=>\s*(\w+))?\s*$',
    RE_FLAGS)

TEST_SUBROUTINE_PATTERN = re.compile(
    r'^\s*subroutine\s+(\w+)\s*(?:\(\s*\)|\(\s*(\w+)\s*\))?\s*$', RE_FLAGS)

END_SUBROUTINE_PATTERN = re.compile(
    r'^\s*end\s+subroutine\s*(\w*)\s*$', RE_FLAGS)

CLASS_DUMMY_ARG_PATTERN = re.compile(
    r'^\s*class\(\s*(\w+)\s*\)[^:]*::\s*(\w+)\s*$', RE_FLAGS)

F_CONT_CHAR = '&'

F_LINE_LENGTH = 80


def get_modules(txt):
    modules = []
    for mod_match in MODULE_PATTERN.finditer(txt):
        modname = mod_match.group(1).lower()
        modstart = mod_match.end()
        endmod_match = END_MODULE_PATTERN.search(txt, mod_match.end())
        if not endmod_match:
            break
        modend = endmod_match.start()
        modules.append((modname, modstart, modend))
    return modules


def get_types_and_procedures(txt, start, end):
    types = {}
    for type_match in TYPE_PATTERN.finditer(txt, start, end):
        typestart = type_match.end()
        endtype_match = END_TYPE_PATTERN.search(txt, typestart)
        if endtype_match is None:
            break
        typeend = endtype_match.start()
        typename = type_match.group(1).lower()

        procedures = {}
        iters = PROCEDURE_PATTERN.finditer(txt, typestart, typeend)
        for proc_match in iters:
            callname, implname = proc_match.groups()
            callname = callname.lower()
            if implname is None:
                implname = callname
            else:
                implname = implname.lower()
            procedures[implname] = callname
        types[typename] = procedures
    return types


def get_test_subroutines(txt, start, end):
    subroutines = []
    for sub_match in TEST_SUBROUTINE_PATTERN.finditer(txt, start, end):
        substart = sub_match.end()
        endsub_match = END_SUBROUTINE_PATTERN.search(txt, substart, end)
        if endsub_match is None:
            break
        subend = endsub_match.start()
        
        subname, subarg = sub_match.groups()
        subname = subname.lower()
        if subarg is None:
            subroutines.append((subname, None))
            continue
        subarg = subarg.lower()

        iters = CLASS_DUMMY_ARG_PATTERN.finditer(txt, substart, subend)
        for dummyarg_match in iters:
            classname = dummyarg_match.group(1).lower()
            argname = dummyarg_match.group(2).lower()
            if argname == subarg:
                subroutines.append((subname, classname))
                continue
    return subroutines


def get_test_method_calls(txt):
    testmethods = []
    modules = get_modules(txt)
    for modname, modstart, modend in modules:
        types_and_procs = get_types_and_procedures(txt, modstart, modend)
        subs = get_test_subroutines(txt, modstart, modend)
        for subname, argtype in subs:
            if argtype is None:
                testmethods.append((modname, None, subname))
            else:
                typeprocs = types_and_procs.get(argtype, {})
                callname = typeprocs.get(subname, None)
                if callname is not None:
                    testmethods.append((modname, argtype, callname))
    return testmethods
    

def get_entities(testmethods):
    modules = {}
    instances = []
    calls = []
    for modname, typename, subname in testmethods:
        if not modname in modules:
            modules[modname] = []
        if typename is None:
            modules[modname].append(subname)
            calls.append((modname, None, subname))
        else:
            modules[modname].append(typename)
            instances.append((modname, typename))
            calls.append((modname, typename, subname))
    return modules, instances, calls


def get_entities_from_files(files):
    modules = {}
    instances = []
    calls = []
    for fname in files:
        fp = open(fname, 'r')
        txt = fp.read()
        fp.close()
        testmethods = get_test_method_calls(txt)
        mods, insts, cls = get_entities(testmethods)
        modules.update(mods)
        instances += insts
        calls += cls
    return modules, instances, calls


def fortran_join(lines):
    fortran_lines = []
    fll0 = F_LINE_LENGTH
    fll1 = fll0 - 1
    fll2 = fll0 - 2
    for line in lines:
        if len(line) <= fll0:
            fortran_lines.append(line)
        else:
            fortran_lines.append(line[0:fll1] + F_CONT_CHAR)
            for ipos in range(fll1 + fll2, len(line) - 1, fll2):
                fortran_lines.append(F_CONT_CHAR + line[ipos - fll2 : ipos] 
                                     + F_CONT_CHAR)
            fortran_lines.append(F_CONT_CHAR + line[ipos:])
    return '\n'.join(fortran_lines)
