#!/usr/bin/env python
# encoding: utf-8
# Bálint Aradi, 2015
import os.path
from waflib import Configure, Logs, Task, TaskGen
import m4
'''Uses M4 as Fortran preprocessor (.F90 -> .f90).

The module assumes, that the m4 file containing the Fortran preprocessor macro
definitions is called 'fppdefs.m4' and is located in the same directory where
the executable bash script m4fpp (variable M4FPP) can be found. Alternatively,
you can set up M4FPP_DEFFILE in conf.env or conf.environ *before* loading the
module, then the macro definition file therein will be used and the search for
an executable m4fpp will be omitted.
'''


################################################################################
# Configure
################################################################################

def configure(conf):
	conf.m4fpp_find_deffile()
	conf.load('m4')
	conf.m4_check_quote_change()
	conf.m4_change_quote('{', '}')
	conf.m4_use_builtin_prefixing()
	conf.env.append_value('M4_FLAGS', conf.env['M4FPP_DEFFILE'])
	conf.m4fpp_check_preprocessor()


@Configure.conf
def m4fpp_find_deffile(conf):
	deffile = conf.env['M4FPP_DEFFILE']
	if not deffile and 'M4FPP_DEFFILE' in conf.environ:
		deffile = conf.environ['M4FPP_DEFFILE']
	if not deffile:
		conf.find_program('m4fpp', mandatory=True)
		m4fpp_dir = os.path.dirname(conf.env['M4FPP'][0])
		conf.start_msg("Checking for file 'fppdefs.m4'")
		fppdefs = conf.find_file('fppdefs.m4', [ m4fpp_dir ])
		if fppdefs:
			deffile = os.path.abspath(fppdefs)
			conf.end_msg(deffile)
	conf.env['M4FPP_DEFFILE'] = deffile


@Configure.conf
def m4fpp_check_preprocessor(conf):
	snippet = '{}_SILENT_M4_BEGIN{}123{}_SILENT_M4_END{}1'
	conf.m4_check_feature('Fortran preprocessing', snippet)


################################################################################
# Build
################################################################################

class m4fpp(m4.m4):

	ext_in = [ '.F90' ]
	ext_out = [ '.f90' ]

	def keyword(self):
		return 'Preprocessing'


# Alias all m4 features as m4fpp
TaskGen.feats['m4fpp'] = TaskGen.feats['m4']


@TaskGen.extension('.F90')
def m4_preprocess_F90(self, node):
	'Preprocess the .F90 files with m4.'

	f90node = node.change_ext('.f90')
	self.create_task('m4fpp', node, [ f90node ])
	if 'fc' in self.features:
		self.source.append(f90node)
 
