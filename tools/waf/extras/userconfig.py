# Routines for simplified user configuration by reading ini file with options.
#
try:
	import configparser
except ImportError:
	import ConfigParser as configparser
from waflib import Configure


def options(opt):
	'''Adds the option for reading in config file which contains waf options and
	environment variables.'''
	msg = 'Read options and environment variables from CONFIGINI'
	opt.add_option('-c', '--read-config', action='store', metavar="CONFIGINI",
				   dest='configini', default=None, help=msg)


@Configure.conf
def load_user_config(conf):
	'''Fills up conf.environ and conf.options from the user defined config file.
	'''
	configini = conf.options.configini
	if configini is not None:
		conf.start_msg("Reading config options from '%s'" % configini)
		try:
			read_config_from_ini(
				configini, [ ('conf.environ', conf.environ, False),
							 ('conf.options', conf.options, True) ])
		except IOError:
			conf.fatal("failed")
		else:
			conf.end_msg("done")


@Configure.conf
def import_os_flags(conf, name, defaults):
	''''''
	conf.start_msg('Applying user settings for %s' % name)
	ignored = set()
	for option, valconv in defaults.items():
		value, converter = valconv
		userval = conf.environ.pop(option, None)
		already_defined = conf.env[option]
		if userval is not None:
			if already_defined:
				ignored.add(option)
			else:
				value = userval
		if value is not None and not already_defined:
			if converter is not None:
				conf.env[option] = converter(value)
			else:
				conf.env[option] = value
	if ignored:
		conf.end_msg('ignored some variables.')
		conf.msg('Ignored variable(s):', " ".join(list(ignored)))
	else:
		conf.end_msg('done')


def read_config_from_ini(fname, sections_targets_attribs, attrib=False):
	'''Reads sections from config file and adds their content to targets.
	'''
	parser = configparser.RawConfigParser()
	parser.optionxform = str
	fp = open(fname, "r")
	parser.readfp(fp)
	fp.close()
	for sect_trg_attr in sections_targets_attribs:
		section, target, attrib = sect_trg_attr
		if not parser.has_section(section):
			continue
		if attrib:
			for name, value in parser.items(section):
				setattr(target, name, value)
		else:
			for name, value in parser.items(section):
				target[name] = value

