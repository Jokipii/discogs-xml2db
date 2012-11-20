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
import psycopg2

class PostgresExporter(object):
	# queries
	add_label = intern("EXECUTE add_label(%s, %s, %s, %s, %s, %s, %s, %s);")
	add_artist = intern("EXECUTE add_artist(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);")
	# queries for release
	add_release = intern("EXECUTE add_release(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);")
	add_release_image = intern("EXECUTE add_release_image(%s,%s,%s,%s,%s,%s);")
	add_release_format = intern("EXECUTE add_release_format(%s,%s,%s,%s,%s);")
	add_release_identifier = intern("EXECUTE add_release_identifier(%s,%s,%s,%s);")
	add_release_label = intern("EXECUTE add_release_label(%s,%s,%s);")
	add_release_video = intern("EXECUTE add_release_video(%s,%s,%s,%s,%s,%s);")
	add_release_artist = intern("EXECUTE add_release_artist(%s,%s,%s,%s,%s);")
	add_release_extraartist = intern("EXECUTE add_release_extraartist(%s,%s,%s,%s,%s,%s,%s);")
	add_track = intern("EXECUTE add_track(%s,%s,%s,%s);")
	add_track_artist = intern("EXECUTE add_track_artist(%s,%s,%s,%s,%s);")
	add_track_extraartist = intern("EXECUTE add_track_extraartist(%s,%s,%s,%s,%s,%s);")
	# queries master
	add_master = intern("EXECUTE add_master(%s, %s, %s, %s, %s, %s, %s, %s);")
	add_master_artist = intern("EXECUTE add_master_artist(%s,%s,%s,%s,%s);")
	add_master_video = intern("EXECUTE add_master_video(%s,%s);")
	add_master_image = intern("EXECUTE add_master_image(%s,%s,%s);")
	# commmon
	add_image = intern("EXECUTE add_image(%s,%s,%s,%s);")
	add_video = intern("EXECUTE add_video(%s,%s,%s,%s,%s);")

	class ExecuteError(Exception):
		def __init__(self, args):
			self.args = args

	def __init__(self, connection_string):
		self.preparedArtist = False
		self.preparedLabel = False
		self.preparedMaster = False
		self.preparedRelease = False
		self.preparedCommon = False
		self.count = 0
		self.connect(connection_string)

	def connect(self, connection_string):
		try:
			self.conn = psycopg2.connect(connection_string)
			self.cur = self.conn.cursor()
			self.execute("SET search_path = discogs; SET work_mem = '1GB';",'')
			self.prepareReleaseQueries()
		except psycopg2.Error, e:
			print "%s" % (e.args)
			raise PostgresExporter.ExecuteError(e.args)

	def execute(self, query, values):
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

	def prepareCommonQueries(self):
		query = """
			PREPARE add_image(text, integer, integer, text) AS
				INSERT INTO image(uri, height, width, uri150) VALUES ($1, $2, $3, $4);
		"""
		self.execute(query, '')
		self.preparedCommon = True

	def prepareLabelQueries(self):
		if not self.preparedCommon:
			self.prepareCommonQueries()
		query = """
			PREPARE add_label(integer, text, text, text, text, text[], text[], quality) AS
				INSERT INTO label(id, name, contactinfo, profile, parent_label, sublabels, urls,
					data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
			
			PREPARE add_label_image(text, integer, image_type) AS
				INSERT INTO labels_images(image_uri, label_id, type) VALUES ($1, $2, $3);
		"""
		self.execute(query, '')
		self.preparedLabel = True

	def prepareArtistQueries(self):
		if not self.preparedCommon:
			self.prepareCommonQueries()
		query = """
			PREPARE add_artist(integer, text, text, text[], text[], text[], text, text[], text[], quality) AS
				INSERT INTO artist(id, name, realname, urls, namevariations, aliases, profile,
					members, groups, data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
			
			PREPARE add_artist_image(text, integer, image_type) AS
				INSERT INTO artists_images(image_uri, artist_id, type) VALUES ($1, $2, $3);
		"""
		self.execute(query, '')
		self.preparedArtist = True

	def prepareReleaseQueries(self):
		query = """
			PREPARE add_release(integer, status, text, character varying(64), character varying(11), 
				text, text[], character varying(32)[], integer, quality) AS
				INSERT INTO release(id, status, title, country, released, notes, genres,
					styles, master_id, data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
			
			PREPARE add_release_image(text, integer, integer, image_type, text, integer) AS
				WITH image AS (
					INSERT INTO image(uri, height, width, uri150) VALUES ($1, $2, $3, $5) RETURNING *
				), release_image AS (
					INSERT INTO releases_images(image_uri, release_id, type) VALUES ($1, $6, $4) RETURNING *
				)
				SELECT * FROM image, release_image;
			
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
			
			PREPARE add_release_video(text, integer, boolean, text, text, integer) AS
				WITH release_video AS (
					INSERT INTO release_video(video_uri, release_id) VALUES ($1, $6) RETURNING *
				), video AS (
					INSERT INTO video(uri, duration, embed, description, title) VALUES ($1, $2, $3, $4, $5) RETURNING *
				)
				SELECT * FROM release_video, video;
		"""
		self.execute(query, '')
		self.preparedRelease = True

	def prepareMasterQueries(self):
		if not self.preparedCommon:
			self.prepareCommonQueries()
		query = """
			PREPARE add_master(integer, integer, text, integer, text, text[], text[], quality) AS
				INSERT INTO master(id, main_release, title, year, notes, genres,
					styles, data_quality) VALUES ($1, $2, $3, $4, $5, $6, $7,$8);
			
			PREPARE add_master_image(text, integer, image_type) AS
				INSERT INTO masters_images(image_uri, master_id, type) VALUES ($1, $2, $3);
			
			PREPARE add_master_artist(integer, integer, text, text, text) AS
				INSERT INTO masters_artists(master_id, artist_id, artist_name, anv, join_relation) VALUES($1, $2, $3, $4, $5);
			
			PREPARE add_master_video(text, integer) AS
				INSERT INTO master_video(video_uri, master_id) VALUES ($1, $2);
			
			PREPARE add_video(text, integer, boolean, text, text) AS
				INSERT INTO video(uri, duration, embed, description, title) VALUES ($1, $2, $3, $4, $5);
		"""
		self.execute(query, '')
		self.preparedMaster = True

	def storeLabel(self, label):
		if not self.preparedLabel:
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

		try:
			self.execute(self.add_label, values)
		except PostgresExporter.ExecuteError as e:
			print "%s" % (e.args)
			return

		for img in label.images:
			if img.uri and len(img.uri) > 29:
				self.execute(self.add_image, (img.uri[29:], img.height, img.width, img.uri150[29:]))
				self.execute("EXECUTE add_label_image(%s,%s,%s);", (img.uri[29:], label.id, img.imageType))
		
		# commit after 1000 label... makes execution faster
		if self.count == 1000:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1

	def storeArtist(self, artist):
		if not self.preparedArtist:
			self.prepareArtistQueries()
		values = []
		values.append(artist.id)
		values.append(artist.name)
		values.append(artist.realname)
		values.append(artist.urls)
		values.append(artist.namevariations)
		values.append(artist.aliases)
		values.append(artist.profile)
		values.append(artist.members)
		values.append(artist.groups)
		values.append(artist.data_quality)

		try:
			self.execute(self.add_artist, values)
		except PostgresExporter.ExecuteError, e:
			print "%s" % (e.args)
			return

		for img in artist.images:
			if img.uri and len(img.uri) > 29:
				self.execute(self.add_image, (img.uri[29:], img.height, img.width, img.uri150[29:]))
				self.execute("EXECUTE add_artist_image(%s,%s,%s);", (img.uri[29:], artist.id, img.imageType))
		
		# commit after 1000 artist... makes execution faster
		if self.count == 1000:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1

	def storeRelease(self, release):
		# we do not store deleted
		if release.status == 'Deleted':
			return
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
		try:
			self.cur.execute(self.add_release, values)
		except PostgresExporter.ExecuteError, e:
			print "%s" % (e.args)
			return

		for img in release.images:
			if img.uri and len(img.uri) > 29:
				self.cur.execute(self.add_release_image, (img.uri[29:], img.height, img.width, img.imageType, img.uri150[29:], release.id))
		
		for fmt in release.formats:
			if len(release.formats) != 0:
				self.cur.execute(self.add_release_format, (release.id, fmt.qty, fmt.name, fmt.descriptions, fmt.text))

		for identifier in release.identifiers:
			self.cur.execute(self.add_release_identifier, (release.id, identifier.type, identifier.value, identifier.description))

		for lbl in release.labels:
			self.cur.execute(self.add_release_label, (release.id, lbl.name, lbl.catno))

		for video in release.videos:
			if video.uri and len(video.uri) > 0:
				self.cur.execute(self.add_release_video, (video.uri, video.duration, video.embed, video.description, video.title, release.id))
		
		if len(release.artists) > 0:
			for artist in release.artists:
				self.cur.execute(self.add_release_artist, (release.id, artist.id, artist.name, artist.anv, artist.join))
		else:
			self.cur.execute(self.add_release_artist, (release.id, None, release.artist, None, None))

		for extr in release.extraartists:
			for role in extr.roles:
				if type(role).__name__ == 'tuple':
					self.cur.execute(self.add_release_extraartist, (release.id, extr.id, extr.name, extr.anv, role[0], role[1], extr.tracks))
				else:
					self.cur.execute(self.add_release_extraartist, (release.id, extr.id, extr.name, extr.anv, role, None, extr.tracks))
		
		for trk in release.tracklist:
			self.cur.execute(self.add_track, (release.id, trk.title, trk.duration[:10], trk.position))
			trackid = self.cur.fetchone()
			for artist in trk.artists:
				self.cur.execute(self.add_track_artist, (trackid, artist.id, artist.name, artist.anv, artist.join))
			#Insert Extraartists for track
			for extr in trk.extraartists:
				for role in extr.roles:
					if type(role).__name__ == 'tuple':
						self.cur.execute(self.add_track_extraartist, (trackid, extr.id, extr.name, extr.anv, role[0], role[1]))
					else:
						self.cur.execute(self.add_track_extraartist, (trackid, extr.id, extr.name, extr.anv, role, None))
		# commit after 100 release...
		if self.count == 100:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1


	def storeMaster(self, master):
		if not self.preparedMaster:
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
		try:
			self.execute(self.add_master, values)
		except PostgresExporter.ExecuteError, e:
			print "%s" % (e.args)
			return
		
		for img in master.images:
			if img.uri and len(img.uri) > 29:
				self.execute(self.add_image, (img.uri[29:], img.height, img.width, img.uri150[29:]))
				self.execute(self.add_master_image, (img.uri[29:], master.id, img.imageType))

		if len(master.artists) > 1:
			for artist in master.artists:
				self.execute(self.add_master_artist, (master.id, artist.id, artist.name, artist.anv, artist.join))
		else:
			if len(master.artists) == 0:  # use anv if no artist name
				self.execute(self.add_master_artist, (master.id, None, master.artist, None, None))
			else:
				self.execute(self.add_master_artist, (master.id, master.artists[0].id, master.artists[0].name, master.artists[0].anv, None))

		for video in master.videos:
			if video.uri and len(video.uri) > 0:
				self.execute(self.add_video, (video.uri, video.duration, video.embed, video.description, video.title))
				self.execute(self.add_master_video, (video.uri, master.id))

		# there are not extraartists on master

		# commit after 500 masters...
		if self.count == 500:
			self.conn.commit()
			self.count = 0
		else:
			self.count = self.count + 1

class PostgresConsoleDumper(PostgresExporter):

	def __init__(self, connection_string):
		super(PostgresConsoleDumper, self).__init__(connection_string)
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
