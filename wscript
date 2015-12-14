import sys
import os
# Set paths to customized waf tools
for path in [ "tools/waf/fortyxima", "tools/waf/extras" ]:
    sys.path.append(os.path.abspath(os.path.join(os.getcwd(), path)))

APPNAME = 'fortyxima'
VERSION = '0.1'

top = '.'
out = '_build'


def options(opt):
    opt.load('fxenv')
    opt.recurse('src')


def configure(conf):
    conf.load('fxenv')
    conf.recurse('src')


def build(bld):
    bld.load('fxenv')
    bld.recurse('src')
    bld.recurse('test')


def test(bld):
    bld.load('fxenv')
    bld.recurse('test')


from waflib import Build
class testContext(Build.BuildContext):
    'Unit tests'
    cmd = 'test'
    fun = 'test'

