from waflib import Task, TaskGen, Utils, Logs, Options

INDENT_STR = ' ' * 4

testlock = Utils.threading.Lock()

@TaskGen.feature('testdriver')
@TaskGen.after_method('apply_link')
def make_tests(self):
    if getattr(self, 'link_task', None):
        tests = getattr(self, 'tests', [])
        tests += get_tests_from_files(self, getattr(self, 'testfiles', []))
        for testname in tests:
            self.create_task('fxutest', self.link_task.outputs, 
                             testname=testname)
        self.bld.add_post_fun(summary)


@TaskGen.taskgen_method
def add_test_result(self, result):
    report_test_result(result)
    self.utest_result = result
    try:
        self.bld.utest_results.append(result)
    except AttributeError:
        self.bld.utest_results = [ result ]
    retval = result[1] if Options.options.stop_on_failure else None
    return retval



class fxutest(Task.Task):

    color = 'PINK'

    def runnable_status(self):
        included_tests = getattr(Options.options, 'include_test', None)
        if included_tests and self.testname not in included_tests:
            return Task.SKIP_ME
        excluded_tests = getattr(Options.options, 'exclude_test', None)
        if excluded_tests and self.testname in excluded_tests:
            return Task.SKIP_ME
        status = super(fxutest, self).runnable_status()
        if status == Task.SKIP_ME:
            status = Task.RUN_ME
        return status


    def run(self):
        execname = self.inputs[0].abspath()
        cwd = self.inputs[0].parent.abspath()
        cmd = [ execname, self.testname ]
        Logs.debug('runner: %r' % (cmd, ))
        proc = Utils.subprocess.Popen(
            cmd, cwd=cwd, stderr=Utils.subprocess.PIPE, 
            stdout=Utils.subprocess.PIPE)
        (stdout, stderr) = proc.communicate()
        result = (self.testname, proc.returncode, stdout, stderr)
        testlock.acquire()
        try:
            return self.generator.add_test_result(result)
        finally:
            testlock.release()


    def keyword(self):
        return 'Test %s via' % (self.testname, )


    def uid(self):
        try:
            return self.uid_
        except AttributeError:
            m = Utils.md5()
            m.update(self.__class__.__name__)
            for x in self.inputs:
                m.update(x.abspath())
            m.update(self.testname)
            self.uid_ = m.digest()
            return self.uid_


def summary(bld):
    results = getattr(bld, 'utest_results', [])
    if results:
        tests_passed = []
        tests_failed = []
        for result in results:
            retcode = result[1]
            if retcode:
                tests_failed.append(result)
            else:
                tests_passed.append(result)
        total = len(results)
        passed = len(tests_passed)
        passed_rel = (100.0 * passed) / float(total)
        failed = len(tests_failed)
        failed_rel = (100.0 * failed) / float(total)
        ndigit = len(str(total))
        formstr = '%%%dd / %d (%%.0f%%%%)' % (ndigit, total)

        if passed and Options.options.list_all_tests:
            Logs.pprint('CYAN', '\nTests passed:')
            for testname, retcode, stdout, stderr in tests_passed:
                Logs.pprint('CYAN', '%s' % (testname, ))
        
        if failed:
            Logs.pprint('RED', '\nTests failed:')
            for testname, retcode, stdout, stderr in tests_failed:
                Logs.pprint('RED', '%s' % (testname, ))
                if Options.options.show_failing_output:
                    if stdout:
                        Logs.pprint('GREY', 'stdout:')
                        Logs.pprint(
                            'GREY', INDENT_STR + 
                            ('\n' + INDENT_STR).join(stdout.split('\n')))
                    if stderr:
                        Logs.pprint('GREY', 'stderr:')
                        Logs.pprint(
                            'GREY', INDENT_STR + 
                            ('\n' + INDENT_STR).join(stderr.split('\n')))

        Logs.pprint('CYAN', '\nTest summary:')
        Logs.pprint('CYAN', 'Passed   ' + formstr % (passed, passed_rel))
        Logs.pprint('CYAN', 'Failed   ' + formstr % (failed, failed_rel))

        if failed:
            bld.fatal('Some tests failed.')


def get_tests_from_files(tgen, files):
    tests = []
    for fname in files:
        node = tgen.path.find_node(fname)
        if not node:
            tgen.bld.fatal('Test file %r not found' % (fname, ))
        txt = node.read()
        for line in txt.split('\n'):
            if not line.startswith('#'):
                tests += line.split()
    return tests


def report_test_result(result):
    testname, retcode, stdout, stderr = result
    opts = Options.options
    if retcode and opts.show_test_failure:
            Logs.pprint('RED', '%s: failed' % (testname, ))


def options(opt):
    optgrp = opt.add_option_group('Unit test options')
    msg = 'Show test failure during testing'
    optgrp.add_option('--show-test-failure', action='store_true',
                      default=False, help=msg)
    msg = 'Show output of failing tests during testing'
    optgrp.add_option('--show-failing-output', action='store_true', 
                      default=False, help=msg)
    msg = 'Stop on first failing test'
    optgrp.add_option('--stop-on-failure', action='store_true', default=False,
                      help=msg)
    msg = 'List all tests (by default only failed tests are listed).'
    optgrp.add_option('--list-all-tests', action='store_true', default=False,
                      help=msg)
    msg = 'Include test for unit testing'
    optgrp.add_option('--include-test', action='append', default=[], 
                      metavar='TEST', help=msg)
    msg = 'Exclude test from unit testing'
    optgrp.add_option('--exclude-test', action='append', default=[],
                      metavar='TEST', help=msg)
