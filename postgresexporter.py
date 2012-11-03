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

#import psycopg2
import uuid
import sys


def untuple(what):
	if type(what) is tuple:
		return list(what)
	else:
		return [what]


def flatten(what):
	return list([i for sub in what for i in untuple(sub)])


class PostgresExporter(object):
	class ExecuteError(Exception):
		def __init__(self, args):
			self.args = args

	def __init__(self, connection_string, data_quality):
		self.prepared = False
		self.count = 0
		self.track_id = 0
		self.connect(connection_string)
		self.min_data_quality = data_quality

	def connect(self, connection_string):
		import psycopg2
		try:
			self.conn = psycopg2.connect(connection_string)
			self.cur = self.conn.cursor()
			self.execute('SET search_path = discogs;','')
		except psycopg2.Error, e:
			print "%s" % (e.args)
			sys.exit()

	def good_quality(self, what):
		if len(self.min_data_quality):
			return what.data_quality.lower() in self.min_data_quality
		return True

	def execute(self, query, values):
		import psycopg2
		try:
			self.cur.execute(query, values)
		except psycopg2.Error as e:
			try:
				print "Error executing: %s" % self.cur.mogrify(query, values)
			except TypeError:
				print "Error executing: %s" % query
			raise PostgresExporter.ExecuteError(e.args)

	def finish(self, completely_done=False):
		self.conn.commit()
		if completely_done:
			self.cur.close()

	def prepareLabelQueries(self):
		query = """
			PREPARE add_label(integer, text, text, text, text, text[], text[], quality) AS
				INSERT INTO label(id, name, contactinfo, profile, parent_label, sublabels, urls,
					data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
			
			PREPARE add_label_image(text, integer) AS
				INSERT INTO labels_images(image_uri, label_id) VALUES ($1, $2);
			
			PREPARE add_image(text, integer, integer, image_type, text) AS
				INSERT INTO image(uri, height, width, type, uri150) VALUES ($1, $2, $3, $4, $5);
		"""
		self.execute(query, '')
		self.prepared = True

	def storeLabel(self, label):
		if not self.good_quality(label):
			return
		if not self.prepared:
			self.prepareLabelQueries()
		values = []
		values.append(label.id)
		values.append(label.name)
		values.append(label.contactinfo)
		values.append(label.profile)
		values.append(label.parentLabel)
		values.append(label.sublabels)
		values.append(label.urls)
		values.append(label.data_quality)

		query = "EXECUTE add_label(%s, %s, %s, %s, %s, %s, %s, %s);"
		try:
			self.execute(query, values)
		except PostgresExporter.ExecuteError as e:
			print "%s" % (e.args)
			return

		for img in label.images:
			if img.uri and len(img.uri) > 29:
				imgQuery = "EXECUTE add_image(%s,%s,%s,%s,%s);"
				self.execute(imgQuery, (img.uri[29:], img.height, img.width, img.imageType, img.uri150[29:]))
				self.execute("EXECUTE add_label_image(%s,%s);", (img.uri[29:], label.id))
		
		# commit after 1000 label... makes execution faster
		if self.count == 1000:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1

	def prepareArtistQueries(self):
		query = """
			PREPARE add_artist(integer, text, text, text[], text[], text[], text, text[], text[], quality) AS
				INSERT INTO artist(id, name, realname, urls, namevariations, aliases, profile,
					members, groups, data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
			
			PREPARE add_artist_image(text, integer) AS
				INSERT INTO artists_images(image_uri, artist_id) VALUES ($1, $2);
			
			PREPARE add_image(text, integer, integer, image_type, text) AS
				INSERT INTO image(uri, height, width, type, uri150) VALUES ($1, $2, $3, $4, $5);
		"""
		self.execute(query, '')
		self.prepared = True

	def storeArtist(self, artist):
		if not self.good_quality(artist):
			return
		if not self.prepared:
			self.prepareArtistQueries()
		values = []
		values.append(artist.id)
		values.append(artist.name)
		values.append(artist.realname)
		values.append(artist.urls)
		values.append(artist.namevariations)
		values.append(artist.aliases)
		values.append(artist.profile)
		values.append(artist.groups)
		values.append(artist.members)
		values.append(artist.data_quality)

		query = "EXECUTE add_artist(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);"
		try:
			self.execute(query, values)
		except PostgresExporter.ExecuteError, e:
			print "%s" % (e.args)
			return

		for img in artist.images:
			if img.uri and len(img.uri) > 29:
				imgQuery = "EXECUTE add_image(%s,%s,%s,%s,%s);"
				self.execute(imgQuery, (img.uri[29:], img.height, img.width, img.imageType, img.uri150[29:]))
				self.execute("EXECUTE add_artist_image(%s,%s);", (img.uri[29:], artist.id))
		
		# commit after 1000 artist... makes execution faster
		if self.count == 1000:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1

	def prepareReleaseQueries(self):
		query = """
			PREPARE add_release(integer, status, text, character varying(64), character varying(11), 
				text, text[], character varying(32)[], integer, quality) AS
				INSERT INTO release(id, status, title, country, released, notes, genres,
					styles, master_id, data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
			
			PREPARE add_release_image(text, integer) AS
				INSERT INTO releases_images(image_uri, release_id) VALUES ($1, $2);
			
			PREPARE add_image(text, integer, integer, image_type, text) AS
				INSERT INTO image(uri, height, width, type, uri150) VALUES ($1, $2, $3, $4, $5);
			
			PREPARE add_release_format(integer, integer, character varying(32), character varying(32)[], text) AS
				INSERT INTO releases_formats(release_id, qty, format_name, descriptions, text) VALUES($1, $2, $3, $4, $5);
			
			PREPARE add_release_label(integer, text, text) AS
				INSERT INTO releases_labels(release_id, label, catno) VALUES($1, $2, $3);
			
			PREPARE add_release_identifier(integer, identifier_type, text, text) AS
				INSERT INTO release_identifier(release_id, type, value, description) VALUES($1, $2, $3, $4);
			
			PREPARE add_release_artist(integer, integer, text, text, text) AS
				INSERT INTO releases_artists(release_id, artist_id, artist_name, anv, join_relation) VALUES($1, $2, $3, $4, $5);
			
			PREPARE add_release_extraartist(integer, integer, text, text, text, text, text) AS
				INSERT INTO releases_extraartists(release_id, artist_id, artist_name, anv, role_name, role_details, tracks)
				VALUES($1, $2, $3, $4, $5, $6, $7);
			
			PREPARE add_track(integer, text, character varying(12), character varying(64)) AS
				INSERT INTO track(release_id, title, duration, position) VALUES($1, $2, $3, $4) RETURNING id;
			
			PREPARE add_track_artist(integer, integer, text, text, text) AS
				INSERT INTO tracks_artists(track_id, artist_id, artist_name, anv, join_relation) VALUES($1, $2, $3, $4, $5);
			
			PREPARE add_track_extraartist(integer, integer, text, text, text, text) AS
				INSERT INTO tracks_extraartists(track_id, artist_id, artist_name, anv, role_name, role_details)
				VALUES($1, $2, $3, $4, $5, $6);
			
			PREPARE add_release_video(text, integer) AS
				INSERT INTO release_video(video_uri, release_id) VALUES ($1, $2);
			
			PREPARE add_video(text, integer, boolean, text, text) AS
				INSERT INTO video(uri, duration, embed, description, title) VALUES ($1, $2, $3, $4, $5);
		"""
		self.execute(query, '')
		self.prepared = True

	def storeRelease(self, release):
		# we do not store deleted
		if release.status == 'Deleted':
			return
		if not self.good_quality(release):
			return
		if not self.prepared:
			self.prepareReleaseQueries()
		values = []
		values.append(release.id)
		values.append(release.status)
		values.append(release.title)
		values.append(release.country)
		values.append(release.released)
		values.append(release.notes)
		values.append(release.genres)
		values.append(release.styles)
		values.append(release.master_id)
		values.append(release.data_quality)

		# INSERT INTO DATABASE
		query = "EXECUTE add_release(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);"
		try:
			self.execute(query, values)
		except PostgresExporter.ExecuteError, e:
			print "%s" % (e.args)
			return

		imgQuery = "EXECUTE add_image(%s,%s,%s,%s,%s);"
		query = "EXECUTE add_release_image(%s,%s);"
		for img in release.images:
			if img.uri and len(img.uri) > 29:
				self.execute(imgQuery, (img.uri[29:], img.height, img.width, img.imageType, img.uri150[29:]))
				self.execute(query, (img.uri[29:], release.id))

		query = "EXECUTE add_release_format(%s,%s,%s,%s,%s);"
		for fmt in release.formats:
			if len(release.formats) != 0:
				self.execute(query, (release.id, fmt.qty, fmt.name, fmt.descriptions, fmt.text))

		query = "EXECUTE add_release_identifier(%s,%s,%s,%s);"
		for identifier in release.identifiers:
			self.execute(query, (release.id, identifier.type, identifier.value, identifier.description))

		query = "EXECUTE add_release_label(%s,%s,%s);"
		for lbl in release.labels:
			self.execute(query, (release.id, lbl.name, lbl.catno))

		videoQuery = "EXECUTE add_video(%s,%s,%s,%s,%s);"
		query = "EXECUTE add_release_video(%s,%s);"
		for video in release.videos:
			if video.uri and len(video.uri) > 0:
				self.execute(videoQuery, (video.uri, video.duration, video.embed, video.description, video.title))
				self.execute(query, (video.uri, release.id))

		query = "EXECUTE add_release_artist(%s,%s,%s,%s,%s);"
		if len(release.artists) > 0:
			for artist in release.artists:
				self.execute(query, (release.id, artist.id, artist.name, artist.anv, artist.join))
		else:
			self.execute(query,	(release.id, None, release.artist, None, None))

		query = "EXECUTE add_release_extraartist(%s,%s,%s,%s,%s,%s,%s);"
		for extr in release.extraartists:
			for role in extr.roles:
				if type(role).__name__ == 'tuple':
					self.execute(query,	(release.id, extr.id, extr.name, extr.anv, role[0], role[1], extr.tracks))
				else:
					self.execute(query,	(release.id, extr.id, extr.name, extr.anv, role, None, extr.tracks))

		query = "EXECUTE add_track(%s,%s,%s,%s);"
		queryAta = "EXECUTE add_track_artist(%s,%s,%s,%s,%s);"
		queryAtea = "EXECUTE add_track_extraartist(%s,%s,%s,%s,%s,%s);"
		for trk in release.tracklist:
			self.execute(query, (release.id, trk.title, trk.duration[:10], trk.position))
			trackid = self.cur.fetchone()
			for artist in trk.artists:
				self.execute(queryAta, (trackid, artist.id, artist.name, artist.anv, artist.join))
			#Insert Extraartists for track
			for extr in trk.extraartists:
				for role in extr.roles:
					if type(role).__name__ == 'tuple':
						self.execute(queryAtea,	(trackid, extr.id, extr.name, extr.anv, role[0], role[1]))
					else:
						self.execute(queryAtea,	(trackid, extr.id, extr.name, extr.anv, role, None))
		# commit after 100 release...
		if self.count == 100:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1

	def prepareMasterQueries(self):
		query = """
			PREPARE add_master(integer, integer, text, integer, text, text[], text[], quality) AS
				INSERT INTO master(id, main_release, title, year, notes, genres,
					styles, data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7,$8);
			
			PREPARE add_master_image(text, integer) AS
				INSERT INTO masters_images(image_uri, master_id) VALUES ($1, $2);
			
			PREPARE add_image(text, integer, integer, image_type, text) AS
				INSERT INTO image(uri, height, width, type, uri150) VALUES ($1, $2, $3, $4, $5);
			
			PREPARE add_master_artist(integer, integer, text, text, text) AS
				INSERT INTO masters_artists(master_id, artist_id, artist_name, anv, join_relation) VALUES($1, $2, $3, $4, $5);
			
			PREPARE add_master_video(text, integer) AS
				INSERT INTO master_video(video_uri, master_id) VALUES ($1, $2);
			
			PREPARE add_video(text, integer, boolean, text, text) AS
				INSERT INTO video(uri, duration, embed, description, title) VALUES ($1, $2, $3, $4, $5);
		"""
		self.execute(query, '')
		self.prepared = True

	def storeMaster(self, master):
		if not self.good_quality(master):
			return
		if not self.prepared:
			self.prepareMasterQueries()

		values = []
		values.append(master.id)
		values.append(master.main_release)
		values.append(master.title)
		values.append(master.year)
		values.append(master.notes)
		values.append(master.genres)
		values.append(master.styles)
		values.append(master.data_quality)

		#INSERT INTO DATABASE
		query = "EXECUTE add_master(%s, %s, %s, %s, %s, %s, %s, %s);"
		try:
			self.execute(query, values)
		except PostgresExporter.ExecuteError, e:
			print "%s" % (e.args)
			return
		for img in master.images:
			if img.uri and len(img.uri) > 29:
				imgQuery = "EXECUTE add_image(%s,%s,%s,%s,%s);"
				self.execute(imgQuery, (img.uri[29:], img.height, img.width, img.imageType, img.uri150[29:]))
				self.execute("EXECUTE add_master_image(%s,%s);", (img.uri[29:], master.id))

		query = "EXECUTE add_master_artist(%s,%s,%s,%s,%s);"
		if len(master.artists) > 1:
			for artist in master.artists:
				self.execute(query, (master.id, artist.id, artist.name, artist.anv, artist.join))
		else:
			if len(master.artists) == 0:  # use anv if no artist name
				self.execute(query,	(master.id, None, master.artist, None, None))
			else:
				self.execute(query, (master.id, master.artists[0].id, master.artists[0].name, master.artists[0].anv, None))

		videoQuery = "EXECUTE add_video(%s,%s,%s,%s,%s);"
		query = "EXECUTE add_master_video(%s,%s);"
		for video in master.videos:
			if video.uri and len(video.uri) > 0:
				self.execute(videoQuery, (video.uri, video.duration, video.embed, video.description, video.title))
				self.execute(query, (video.uri, master.id))

		# there are not extraartists on master

		# commit after 500 masters...
		if self.count == 500:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1

class PostgresConsoleDumper(PostgresExporter):

	def __init__(self, connection_string, data_quality):
		super(PostgresConsoleDumper, self).__init__(connection_string, data_quality)
		self.q = lambda x: "'%s'" % x.replace("'", "\\'") if not( type(x) is int or type(x) is type(None)) else x

	def connect(self, connection_string):
		pass

	def qs(self, what):
		ret = []
		for w in what:
			if type(w) == list:
				ret.append(self.qs(w))
			else:
				#print "q(%s)==%s" % (w, self.q(w))
				ret.append(self.q(w))

		return ret

	def execute(self, query, params):
		qparams = self.qs(params)
		print(query % tuple(qparams))

	def finish(self, completely_done=False):
		pass
