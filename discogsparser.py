#!/usr/bin/python
# -*- coding: utf-8 -*-
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

import xml.sax.handler
import xml.sax
import sys
import jsonexporter
import argparse # in < 2.7 pip install argparse
import gzip
from os import path
from model import ParserStopError
from collections import deque

#sys.setdefaultencoding('utf-8')
options = None

exporters = { 'json': 'jsonexporter.JsonConsoleExporter', 
	'pgsql' : 'postgresexporter.PostgresExporter', 
	'pgdump': 'postgresexporter.PostgresConsoleDumper',
	'couch' : 'couchdbexporter.CouchDbExporter',
	'mongo' : 'mongodbexporter.MongoDbExporter',
	}

# http://www.discogs.com/help/voting-guidelines.html
data_quality_values = ( 'Needs Vote',
		'Complete And Correct', 
		'Correct',
		'Needs Minor Changes',
		'Needs Major Changes',
		'Entirely Incorrect',
		'Entirely Incorrect Edit'
		)


def first_file_match(file_pattern):
	global options
	matches = filter(lambda f: file_pattern in f, options.file)
	return matches[0] if len(matches) > 0 else None


def parse(parser, exporter, entity_type, handler):
	global options
	input_file = None
	match_string = '_%s.xml' % entity_type
	in_file = first_file_match(match_string)
	if options.date is not None:
		input_file = "discogs_%s_%s.xml.gz" % (options.date, entity_type)
		if not path.exists(input_file):
			input_file = "discogs_%s_%s.xml" % (options.date, entity_type)
	elif in_file is not None:
		input_file = in_file
	if input_file is None:
		return
	elif not path.exists(input_file):
		return
	parser.setContentHandler(handler(exporter))
	try:
		if input_file.endswith('.gz'):
			parser.parse(gzip.open(input_file, 'rb'))
		else:
			parser.parse(input_file)
	except ParserStopError as pse:
		print "Parsed %d %s then stopped as requested." % (pse.records_parsed, entity_type)


def artistHandler(exporter):
	global options
	from discogsartistparser import ArtistHandler
	return ArtistHandler(exporter, stop_after=options.n, ignore_missing_tags = options.ignore_unknown_tags)

def labelHandler(exporter):
	global options
	from discogslabelparser import LabelHandler
	return LabelHandler(exporter, stop_after=options.n, ignore_missing_tags = options.ignore_unknown_tags)

def releaseHandler(exporter):
	global options
	from discogsreleaseparser import ReleaseHandler
	return ReleaseHandler(exporter, stop_after=options.n, ignore_missing_tags = options.ignore_unknown_tags)

def masterHandler(exporter):
	global options
	from discogsmasterparser import MasterHandler
	return MasterHandler(exporter, stop_after=options.n, ignore_missing_tags = options.ignore_unknown_tags)



def select_exporter(options):
	global exporters
	if options.output is None:
		return exporters['json'] 
	
	if exporters.has_key(options.output):
		return exporters[options.output]
	# should I be throwing an exception here?
	return exporters['json']

def make_exporter(options):
	exp_module = select_exporter(options)

	parts = exp_module.split('.')
	m = __import__('.'.join(parts[:-1]))
	for i in xrange(1, len(parts)):
		m = getattr(m, parts[i])
	
	data_quality = list(x.strip().lower() for x in (options.data_quality or '').split(',') if x)
	return m(options.params, data_quality=data_quality)
		


def main(argv):
	global exporters
	opt_parser = argparse.ArgumentParser(
			description='Parse discogs release',
			epilog='''
You must specify either -d DATE or some files.
JSON output prints to stdout, any other output requires
that --params is used, e.g.:
--output pgsql
--params "host=localhost dbname=discogs user=pguser"

--output couchdb
--params "http://localhost:5353/"
'''
			)
	opt_parser.add_argument('-n', type=int, help='Number of records to parse')
	opt_parser.add_argument('-d', '--date', help='Date of release. For example 20110301')
	opt_parser.add_argument('-o', '--output', choices=exporters.keys(), default='json', help='What to output to')
	opt_parser.add_argument('-p', '--params', help='Parameters for output, e.g. connection string')
	opt_parser.add_argument('-i', '--ignore-unknown-tags', action='store_true', dest='ignore_unknown_tags', help='Do not error out when encountering unknown tags')
	opt_parser.add_argument('-q', '--quality', dest='data_quality', help='Comma-separated list of permissable data_quality values.')
	opt_parser.add_argument('file', nargs='*', help='Specific file(s) to import. Default is to parse artists, labels, releases matching -d')
	global options
	options = opt_parser.parse_args(argv)
	print(options)

	if options.date is None and len(options.file) == 0:
		opt_parser.print_help()
		sys.exit(1)

	exporter = make_exporter(options)
	parser = xml.sax.make_parser()
	try:
		parse(parser, exporter, 'artists', artistHandler)
		parse(parser, exporter, 'labels', labelHandler)
		parse(parser, exporter, 'releases', releaseHandler)
		parse(parser, exporter, 'masters', masterHandler)
	finally:
		exporter.finish(completely_done = True)

if __name__ == "__main__":
	main(sys.argv[1:])
