#!/usr/bin/env python
# encoding: utf-8
# Bálint Aradi, 2015
'''M4 preprocessor (currently only works with GNU M4)

Implements the M4 preprocessor. To keep it as flexible as possible, the task is
not bound to any file extension. By subclassing it, you can easily create
extension bound M4 preprocessors, like in the example below, where it is used to
preprocess Fortran source files:

class m4fpp(m4.m4):
	ext_in = [ '.F90' ]
	ext_out = [ '.f90' ]

TaskGen.feats['m4fpp'] = TaskGen.feats['m4']

@TaskGen.extension('.F90')
def m4_preprocess_F90(self, node):
	f90node = node.change_ext('.f90')
	self.create_task('m4fpp', node, [ f90node ])
	if 'fc' in self.features:
		self.source.append(f90node)

'''
import re
from waflib import Configure, Context, Errors, Logs, Task, TaskGen, Utils
from waflib.Tools import ccroot

ccroot.USELIB_VARS['m4'] = set(['DEFINES', 'INCLUDES'])


################################################################################
# Configure
################################################################################


def configure(conf):
	conf.find_program('m4', var='M4')
	conf.m4_get_version()
	conf.m4_flags()
	conf.m4_add_user_flags()
	conf.m4_check_preprocessor()


@Configure.conf
def m4_flags(conf):
	'''Define common configuration flags.'''
		
	env = conf.env
	env['M4_FLAGS'] = []
	env['M4_PREFIX_FLAG'] = [ '-P' ]
	env['M4_STDIN_INPUT_FLAG'] = [ '-' ]
	env['M4_INCPATH_ST'] = '-I%s'
	env['M4_DEFINES_ST'] = '-D%s'
	env['M4_LEFT_QUOTE'] = '`'
	env['M4_RIGHT_QUOTE'] = '\''
	env['M4_BUILTIN_PREFIX'] = ''


@Configure.conf
def m4_add_user_flags(conf):
	'''Import user settings for M4.'''
	conf.add_os_flags('M4_FLAGS', dup=False)


@Configure.conf
def m4_change_quote(conf, lquote, rquote):
	'''Signalizes that M4 scripts contain overriden quotes'''
	conf.env['M4_LEFT_QUOTE'] = lquote
	conf.env['M4_RIGHT_QUOTE'] = rquote


@Configure.conf
def m4_get_version(conf):
	'''Determines GNU M4 version number'''
	VERSION_REGEX = (r'm4 \(GNU M4\) (?P<major>\d+)\.(?P<minor>\d+)'
					 '\.(?P<patch>\d+)')

	conf.start_msg('Checking M4 version')
	try:
		out = conf.cmd_and_log(conf.env['M4'] + [ '--version', ], 
							   output=Context.STDOUT)
	except Errors.WafError:
		conf.fatal('cannot determine GNU M4 version')

	version_regexp = re.compile(VERSION_REGEX, re.IGNORECASE)
	match = version_regexp.search(out)
	if not match:
		conf.fatal('cannot determine GNU M4 version')
	mg = match.group
	version = (mg('major'), mg('minor'))
	conf.env['M4_VERSION'] = version
	conf.end_msg('%s.%s' % version)


@Configure.conf
def m4_check_feature(conf, feature, snippet, varname=None):
	'''Checks a certain M4 feature.

	It passes to M4 a given code snippet. If the result after processing
	is the string "1", the feature is considered to work otherwise not.
	If variable name is passed, an according entry is created in conf.env,
	with a logical as value indicating the success of the check.
	
	:param feature: Name of the feature which is checked
	:type feature: string
	:param snippet: Code to be passed to M4.
	:type snippet: string
	:param varname: Name in conf.env to store the check result as logical.
	:type varname: string
	'''
	conf.start_msg('Checking M4 ' + feature)
	m4options = conf.env['M4_FLAGS'] + conf.env['M4_STDIN_INPUT_FLAG']
	out = conf.cmd_and_log(conf.env['M4'] + m4options, input=snippet, 
						   output=Context.STDOUT, quiet=Context.BOTH)
	works = (out.strip() == '1')
	if varname is not None:
		conf.env[varname] = works
	if not works:
		conf.end_msg('not working')
		conf.fatal('M4 ' + feature + ' not working')
	conf.end_msg('working')


@Configure.conf
def m4_check_preprocessor(conf):
	'''Checks whether preprocessor works with current flags.'''
	snippet = "%sdefine(`test',1)test" % conf.env['M4_BUILTIN_PREFIX']
	conf.m4_check_feature('preprocessor', snippet)
	

@Configure.conf
def m4_check_quote_change(conf):
	'''Checks whether quotes can be changed via changequote()'''
	snippet = ('%(pref)schangequote({,})%(pref)sdefine({test},1)test' 
			   % {'pref': conf.env['M4_BUILTIN_PREFIX']})
	conf.m4_check_feature('quote changing', snippet)


@Configure.conf
def m4_use_builtin_prefixing(conf):
	'''Turns builtin prefixing on.'''
	conf.env.append_unique('M4_FLAGS', conf.env['M4_PREFIX_FLAG'])
	conf.env['M4_BUILTIN_PREFIX'] = 'm4_'


################################################################################
# Build
################################################################################


class m4(Task.Task):

	'''M4 preprocessor task.
	
	It uses a similar strategy as fc uses for detecting Fortran files includes.
	'''
	
	run_str = '${M4} ${M4_FLAGS} ${M4_INCPATH_ST:INCPATHS} ' \
			  '${M4_DEFINES_ST:DEFINES} ${SRC} > ${TGT}'

	color = 'CYAN'


	def keyword(self):
		return 'Processing'


	def scan(self):
		prefix = self.env['M4_BUILTIN_PREFIX']
		lquote = self.env['M4_LEFT_QUOTE']
		rquote = self.env['M4_RIGHT_QUOTE']
		parser = M4IncludeParser(prefix, lquote, rquote, 
								 self.generator.includes_nodes)
		nodes, names = parser.parse(self.inputs[0])
		if Logs.verbose:
			Logs.debug('deps: deps for %r: %r; unresolved: %r' 
					   % (self.inputs, nodes, names))
		return (nodes, names)


TaskGen.feature('m4')(ccroot.propagate_uselib_vars)
TaskGen.feature('m4')(ccroot.apply_incpaths)


################################################################################
# Helper routines
################################################################################


class M4IncludeParser(object):

	'''Parser for include() statements in M4 files.

	It can not handle conditional includes and the file name argument of the
	include builtin must be literal and not the result of an macro expansion.
	'''

	# Include file pattern, opening and closing quoute must be replaced inside.
	INCLUDE_REGEX = r'^\s*%sinclude\([%s]?(?P<incfile>.+?)[%s]?\)'


	def __init__(self, builtinprefix, lquote, rquote, incpaths):
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

		# Regexp for include statements
		self._inc_pattern = re.compile(
				self.INCLUDE_REGEX % (builtinprefix, lquote, rquote),
				re.IGNORECASE | re.MULTILINE)


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
		matches = self._inc_pattern.finditer(txt)
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
		
