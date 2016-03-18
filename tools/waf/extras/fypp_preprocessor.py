#!/usr/bin/env python
# encoding: utf-8
# Bálint Aradi, 2016

'''Uses Fypp as Fortran preprocessor (.F90 -> .f90).'''

import re
import os.path
from waflib import Configure, Logs, Task, TaskGen, Tools
try:
	import fypp
except ImportError:
	fypp = None


Tools.ccroot.USELIB_VARS['fypp'] = set([ 'DEFINES', 'INCLUDES' ])

FYPP_INCPATH_ST = '-I%s'
FYPP_DEFINES_ST = '-D%s'
FYPP_LINENUM_FLAG = '-n'


################################################################################
# Configure
################################################################################

def configure(conf):
	fypp_check(conf)
        fypp_add_user_flags(conf)
	

@Configure.conf
def fypp_add_user_flags(conf):
	'''Import user settings for Fypp.'''
	conf.add_os_flags('FYPP_FLAGS', dup=False)


@Configure.conf
def fypp_check(conf):
	'''Check for Fypp.'''
	conf.start_msg('Checking for fypp module')
	if fypp is None:
		conf.fatal('Python module \'fypp\' could not be imported.')
	version = fypp.VERSION
	version_regexp = re.compile(r'^(?P<major>\d+)\.(?P<minor>\d+)'\
		'(?:\.(?P<patch>\d+))?$')
	match = version_regexp.search(version)
	if not match:
		conf.fatal('cannot parse fypp version string')
	version = (match.group('major'), match.group('minor'))
	conf.env['FYPP_VERSION'] = version
	conf.end_msg('found (version %s.%s)' % version)


################################################################################
# Build
################################################################################

class fypp_preprocessor(Task.Task):
		
	ext_in = [ '.F90' ]
	ext_out = [ '.f90' ]

	color = 'CYAN'

	def keyword(self):
		return 'Processing'

	def run(self):
                opts = fypp.FyppOptions()
                argparser = fypp.get_option_parser()
                args = [FYPP_LINENUM_FLAG]
                args += self.env.FYPP_FLAGS
		args += [FYPP_DEFINES_ST % ss for ss in self.env['DEFINES']]
		args += [FYPP_INCPATH_ST % ss for ss in self.env['INCLUDES']]
                opts = argparser.parse_args(args, namespace=opts)
                infile = self.inputs[0].abspath()
                outfile = self.outputs[0].abspath()
                if Logs.verbose:
                        Logs.debug('runner: fypp.Fypp %r %r %r' 
                                   % (args, infile, outfile))
                
		tool = fypp.Fypp(opts)
		tool.process_file(infile, outfile)
		return 0

	def scan(self):
		parser = FyppIncludeParser(self.generator.includes_nodes)
		nodes, names = parser.parse(self.inputs[0])
		if Logs.verbose:
			Logs.debug('deps: deps for %r: %r; unresolved: %r' 
				% (self.inputs, nodes, names))
		return (nodes, names)


TaskGen.feature('fypp')(Tools.ccroot.propagate_uselib_vars)
TaskGen.feature('fypp')(Tools.ccroot.apply_incpaths)


@TaskGen.extension('.F90')
def fypp_preprocess_F90(self, node):
	'Preprocess the .F90 files with Fypp.'

	f90node = node.change_ext('.f90')
	self.create_task('fypp_preprocessor', node, [ f90node ])
	if 'fc' in self.features:
		self.source.append(f90node)
 

################################################################################
# Helper routines
################################################################################

class FyppIncludeParser(object):

	'''Parser for include directives in files preprocessed by Fypp.

	It can not handle conditional includes.
	'''

	# Include file pattern, opening and closing quoute must be replaced inside.
	INCLUDE_PATTERN = re.compile(r'^\s*#:include\s*(["\'])(?P<incfile>.+?)\1',
		re.MULTILINE)


	def __init__(self, incpaths):
		'''Initializes the parser.

		:param quotes: Tuple containing the opening and closing quote sign.
		:type quotes: tuple
		'''
		# Nodes still to be processed
		self._waiting = []
		
		# Files we have already processed
		self._processed = set()

		# List of dependent nodes
		self._dependencies = []
		
		# List of unresolved dependencies
		self._unresolved = set()

		# Paths to consider when checking for includes
		self._incpaths = incpaths


	def parse(self, node):
		'''Parser the includes in a given node.
		
		:return: Tuple with two elements: list of dependent nodes and list of
			unresolved depencies.
		'''
		self._waiting = [ node, ]
		# self._waiting is eventually extended during _process() -> iterate
		while self._waiting:
			curnode = self._waiting.pop(0)
			self._process(curnode)
		return (self._dependencies, list(self._unresolved))


	def _process(self, node):
		incfiles = self._get_include_files(node)
		for incfile in incfiles:
			if incfile in self._processed:
				continue
			self._processed.add(incfile)
			incnode = self._find_include_node(node, incfile)
			if incnode:
				self._dependencies.append(incnode)
				self._waiting.append(incnode)
			else:
				self._unresolved.add(incfile)


	def _get_include_files(self, node):
		txt = node.read()
		matches = self.INCLUDE_PATTERN.finditer(txt)
		incs = [ match.group('incfile') for match in matches ]
		return incs


	def _find_include_node(self, node, filename):
		for incpath in self._incpaths:
			incnode = incpath.find_resource(filename)
			if incnode:
				break
		else:
			incnode = node.parent.find_resource(filename)
		return incnode
