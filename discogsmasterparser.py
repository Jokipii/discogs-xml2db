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
import model
import re

class MasterHandler(xml.sax.handler.ContentHandler):
	def __init__(self, exporter, stop_after=0, ignore_missing_tags=False):
		self.knownTags = (
							'anv',
							'id',
							'artist',
							'artists',
							'country',
							'data_quality',
							'description',
							'descriptions', #'duration', #'extraartists', #'format', #'formats',
							'genre', 'genres',
							'image',
							'images',
							'join',
							'label', 'labels',
							'masters', 'master',
							'main_release',
							'name',
							'notes',
							'position', #'release', #'released', #'releases',
							'role',
							'style',
							'styles',
							'title',
							'track', #'tracklist',
							'tracks',
							'url', #'urls',
							'videos', 'video',
							'year'
							)
		self.master = None
		self.buffer = ''
		self.unknown_tags = []
		self.exporter = exporter
		self.stop_after = stop_after
		self.ignore_missing_tags = ignore_missing_tags
		self.stack = []
		self.masterCounter = 0

	def startElement(self, name, attrs):
		if not name in self.knownTags:
			if not self.ignore_missing_tags:
				print "Error: Unknown Master element '%s'." % name
				sys.exit()
			elif not name in self.unknown_tags:
				self.unknown_tags.append(name)
		self.stack.append(name)
		if name == 'master':
			self.master = model.Master()
			self.master.id = int(attrs['id'])
		elif name == "image":
			img = model.ImageInfo()
			img.height = attrs["height"]
			img.imageType = attrs["type"]
			img.uri = attrs["uri"]
			img.uri150 = attrs["uri150"]
			img.width = attrs["width"]
			self.master.images.append(img)
			if len(attrs) != 5:
				print "ATTR ERROR"
				print attrs
				sys.exit()
		elif name == "video":
			vid = model.Video()
			vid.duration = attrs["duration"]
			vid.embed = attrs["embed"]
			vid.uri = attrs["src"]
			self.master.videos.append(vid)
		elif name == "artist":
			self.master.artists.append(model.ArtistCredit())

	def characters(self, data):
		self.buffer += data

	def endElement(self, name):
		self.buffer = self.buffer.strip()
		if name == 'title':
			if len(self.buffer) != 0:
				if self.stack[-2] == 'master':
					self.master.title = self.buffer
				if self.stack[-2] == 'video':
					self.master.videos[-1].title = self.buffer
		if name == 'description':
			if len(self.buffer) != 0:
				if self.stack[-2] == 'video':
					self.master.videos[-1].description = self.buffer
		elif name == 'main_release':
			if len(self.buffer) != 0:
				self.master.main_release = self.buffer
		elif name == 'year':
			if len(self.buffer) != 0:
				self.master.year = int(self.buffer)
		elif name == 'notes':
			if len(self.buffer) != 0:
				self.master.notes = self.buffer
		elif name == 'genre':
			if len(self.buffer) != 0:
				self.master.genres.append(self.buffer)
				#global genres
				#if not genres.has_key(self.buffer):
				#  genres[self.buffer] = Genre(self.buffer)
		elif name == 'style':
			if len(self.buffer) != 0:
				self.master.styles.append(self.buffer)
				#global styles
				#if not styles.has_key(self.buffer):
				#  styles[self.buffer] = Style(self.buffer)
		elif name == 'id':
			if len(self.buffer) != 0:
				self.master.artists[-1].id = int(self.buffer)
		elif name == 'name':
			if len(self.buffer) != 0:
				self.master.artists[-1].name = self.buffer
		elif name == 'anv':
			if self.stack[-3] == 'artists' and self.stack[-4] == 'master':
				if len(self.buffer) != 0:
					self.master.artists[-1].anv = self.buffer
		elif name == 'join':
			if len(self.buffer) != 0:
				self.master.artists[-1].join = self.buffer
		elif name == 'role':
			if len(self.buffer) != 0:
				#print "ROLE PRE" + str(self.buffer)
				roles_list = re.findall('([^[,]+(?:\[[^]]+])?)+', self.buffer)  # thanks to jlatour
				#print "ROLE POST" + str(self.buffer)
				for role in roles_list:
					role = role.strip()
					lIndex = role.find('[')
					if lIndex != -1:
						rIndex = role.find(']')
						description = role[lIndex + 1: rIndex]
						role = (role[:lIndex].strip(), description)
					self.master.extraartists[-1].roles.append(role)
		elif name == 'data_quality':
			if len(self.buffer) != 0:
				self.master.data_quality = self.buffer
		elif name == 'master':
			# end of tag
			len_a = len(self.master.artists)
			if len_a == 0:
				sys.stderr.writelines("Ignoring Master %s with no artist. Dictionary: %s\n" % (self.master.id, self.master.__dict__))
			else:
				if len_a == 1:
					self.master.artist = self.master.artists[0]
				else:
					for j in self.master.artists:
						self.master.artist += '%s %s ' % (j.name, j.join)
					self.master.artist += self.master.artists[-1].name

				self.masterCounter += 1
				#'''PREPARE FOR DATABASE
				self.exporter.storeMaster(self.master)

				if self.stop_after > 0 and self.masterCounter >= self.stop_after:
					self.endDocument()
					if self.ignore_missing_tags and len(self.unknown_tags) > 0:
						print 'Encountered some unknown Master tags: %s' % (self.unknown_tags)
					raise model.ParserStopError(self.masterCounter)

		if self.stack[-1] == name:
			self.stack.pop()
		self.buffer = ''

	def endDocument(self):
		#print [genre for genre in genres]
		#print [style for style in styles]
		#print [format for format in formats]
		#print [dsc for dsc in descriptions]
		#print [j for j in joins]
		#print [(role, roles[role]) for role in roles]
		#print len(roles)
		self.exporter.finish()
