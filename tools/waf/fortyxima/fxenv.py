# Import all settings needed for Fortyxima compilation
import os.path
import fxtools

def options(opt):
    opt.load('userconfig')
    opt.load('fxunit')
    #opt.load('fx_unit_test')


def configure(conf):
    conf.load('userconfig')
    conf.load_user_config()
    conf.load('fxunit')
    #conf.load('fx_unit_test')
    # Direct specification of the fppdefs.m4 file
    conf.env['M4FPP_DEFFILE'] = os.path.join(conf.path.abspath(), 
                                             "tools/m4fpp/fppdefs.m4")


def build(bld):
    fxtools.fix_fc_keyword()
