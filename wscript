APPNAME = 'fortyxima'
VERSION = '0.1'

top = '.'
out = '_build'


def options(opt):
    opt.recurse('src')


def configure(conf):
    conf.recurse('src')


def build(bld):
    bld.recurse('src')
