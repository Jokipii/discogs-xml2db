SET search_path = discogs;



-- Because we havent enforced contraints when we added data in database we need to do some clearing here
WITH orig AS (SELECT uri, min(id) FROM image GROUP BY uri HAVING count(id) > 1)
DELETE FROM image USING orig WHERE image.uri = orig.uri AND image.id <> orig.min;

WITH orig AS (
	SELECT image_uri, label_id, min(id) FROM labels_images
	GROUP BY image_uri, label_id HAVING count(id) > 1
)
DELETE FROM labels_images USING orig 
	WHERE labels_images.image_uri = orig.image_uri
	AND labels_images.id <> orig.min
	AND labels_images.label_id = orig.label_id;

WITH orig AS (
	SELECT image_uri, artist_id, min(id) FROM artists_images
	GROUP BY image_uri, artist_id HAVING count(id) > 1
)
DELETE FROM artists_images USING orig
	WHERE artists_images.image_uri = orig.image_uri
	AND artists_images.id <> orig.min
	AND artists_images.artist_id = orig.artist_id;

WITH orig AS (
	SELECT image_uri, master_id, min(id) FROM masters_images
	GROUP BY image_uri, master_id HAVING count(id) > 1
)
DELETE FROM masters_images USING orig
	WHERE masters_images.image_uri = orig.image_uri	
	AND masters_images.id <> orig.min
	AND masters_images.master_id = orig.master_id;

WITH orig AS (
	SELECT image_uri, release_id, min(id) FROM releases_images
	GROUP BY image_uri, release_id HAVING count(id) > 1
)
DELETE FROM releases_images USING orig
	WHERE releases_images.image_uri = orig.image_uri
	AND releases_images.id <> orig.min
	AND releases_images.release_id = orig.release_id;

WITH orig AS (SELECT uri, min(id) FROM video GROUP BY uri HAVING count(id) > 1)
DELETE FROM video USING orig WHERE video.uri = orig.uri AND video.id <> orig.min;

WITH orig AS (
	SELECT video_uri, master_id, min(id) FROM master_video
	GROUP BY video_uri, master_id HAVING count(id) > 1
)
DELETE FROM master_video USING orig
	WHERE master_video.video_uri = orig.video_uri	
	AND master_video.id <> orig.min
	AND master_video.master_id = orig.master_id;

WITH orig AS (
	SELECT video_uri, release_id, min(id) FROM release_video
	GROUP BY video_uri, release_id HAVING count(id) > 1
)
DELETE FROM release_video USING orig
	WHERE release_video.video_uri = orig.video_uri
	AND release_video.id <> orig.min
	AND release_video.release_id = orig.release_id;

--ALTER TABLE image DROP COLUMN id;
--ALTER TABLE labels_images DROP COLUMN id;
--ALTER TABLE artists_images DROP COLUMN id;
--ALTER TABLE masters_images DROP COLUMN id;
--ALTER TABLE releases_images DROP COLUMN id;
--ALTER TABLE video DROP COLUMN id;
--ALTER TABLE master_video DROP COLUMN id;
--ALTER TABLE release_video DROP COLUMN id;



-- update some data types and fields
-- little weird way to do it is used here because more direct way causing out of memory error
ALTER TABLE release ADD COLUMN genre_tmp genre[];
UPDATE release SET genre_tmp = genres::genre[];
ALTER TABLE release ALTER COLUMN genres SET DATA TYPE genre[] USING genre_tmp;
ALTER TABLE release DROP COLUMN genre_tmp;

ALTER TABLE master ADD COLUMN genre_tmp genre[];
UPDATE master SET genre_tmp = genres::genre[];
ALTER TABLE master ALTER COLUMN genres SET DATA TYPE genre[] USING genre_tmp;
ALTER TABLE master DROP COLUMN genre_tmp;

-- before setting releases_formats.format we need to ensure that format_name field have only correct values
-- uncorrect values are moved to additional text description field and format_name is set to 'Unknown'
UPDATE releases_formats SET text = format_name||text, format_name='Unknown' WHERE format_name <> ALL(array[
	'Vinyl', 'Acetate', 'Flexi-disc', 'Lathe Cut', 'Shellac', 'Pathé Disc', 'Edison Disc', 
	'Cylinder', 'CD', 'CDr', 'CDV', 'DVD', 'DVDr', 'HD DVD', 'HD DVD-R', 'Blu-ray', 
	'Blu-ray-R', '4-Track Cartridge', '8-Track Cartridge', 'Cassette', 'DAT', 'DCC', 
	'Microcassette', 'Reel-To-Reel', 'Betamax', 'VHS', 'Video 2000', 'Laserdisc', 
	'SelectaVision', 'VHD', 'Minidisc', 'MVD', 'UMD', 'Floppy Disk', 'File', 
	'Memory Stick', 'Hybrid', 'All Media', 'Box Set'
]);
UPDATE releases_formats SET format = format_name::format;
ALTER TABLE releases_formats DROP COLUMN format_name;



-- this might be good point to do VACUUM ANALYZE



-- primary keys
ALTER TABLE ONLY label ADD CONSTRAINT label_pkey PRIMARY KEY (id);
ALTER TABLE ONLY master ADD CONSTRAINT master_pkey PRIMARY KEY (id);
ALTER TABLE ONLY style ADD CONSTRAINT style_pkey PRIMARY KEY (id);
ALTER TABLE ONLY format ADD CONSTRAINT format_pkey PRIMARY KEY (id);

ALTER TABLE ONLY release ADD CONSTRAINT release_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_labels ADD CONSTRAINT releases_labels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY release_identifier ADD CONSTRAINT release_identifier_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_formats ADD CONSTRAINT releases_formats_pkey PRIMARY KEY (id);

ALTER TABLE ONLY track ADD CONSTRAINT track_pkey PRIMARY KEY (id);

ALTER TABLE ONLY artist ADD CONSTRAINT artist_pkey PRIMARY KEY (id);
ALTER TABLE ONLY masters_artists ADD CONSTRAINT masters_artists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_artists ADD CONSTRAINT releases_artists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tracks_artists ADD CONSTRAINT tracks_artists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_extraartists ADD CONSTRAINT releases_extraartists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tracks_extraartists ADD CONSTRAINT tracks_extraartists_pkey PRIMARY KEY (id);

ALTER TABLE ONLY image ADD CONSTRAINT image_pkey PRIMARY KEY (uri);
ALTER TABLE ONLY labels_images ADD CONSTRAINT labels_images_pkey PRIMARY KEY (label_id, image_uri);
ALTER TABLE ONLY masters_images ADD CONSTRAINT masters_images_pkey PRIMARY KEY (master_id, image_uri);
ALTER TABLE ONLY releases_images ADD CONSTRAINT releases_images_pkey PRIMARY KEY (release_id, image_uri);
ALTER TABLE ONLY artists_images ADD CONSTRAINT artists_images_pkey PRIMARY KEY (artist_id, image_uri);

ALTER TABLE ONLY video ADD CONSTRAINT video_pkey PRIMARY KEY (uri);
ALTER TABLE ONLY master_video ADD CONSTRAINT master_video_pkey PRIMARY KEY (master_id, video_uri);
ALTER TABLE ONLY release_video ADD CONSTRAINT release_video_pkey PRIMARY KEY (release_id, video_uri);


-- foreign keys
ALTER TABLE ONLY releases_labels
	ADD CONSTRAINT releases_labels_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY release_identifier
	ADD CONSTRAINT release_identifier_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY releases_formats
	ADD CONSTRAINT releases_formats_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY releases_formats
	ADD CONSTRAINT releases_formats_fk_format_name FOREIGN KEY (format_name) REFERENCES format(name);

ALTER TABLE ONLY track
	ADD CONSTRAINT track_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);

ALTER TABLE ONLY masters_artists
	ADD CONSTRAINT masters_artists_fk_master_id FOREIGN KEY (master_id) REFERENCES master(id);
ALTER TABLE ONLY releases_artists
	ADD CONSTRAINT releases_artists_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY tracks_artists
	ADD CONSTRAINT tracks_artists_fk_track_id FOREIGN KEY (track_id) REFERENCES track(id);
ALTER TABLE ONLY releases_extraartists
	ADD CONSTRAINT releases_extraartists_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY tracks_extraartists
	ADD CONSTRAINT tracks_extraartists_fk_track_id FOREIGN KEY (track_id) REFERENCES track(id);

ALTER TABLE ONLY labels_images
	ADD CONSTRAINT labels_images_fk_label_id FOREIGN KEY (label_id) REFERENCES label(id);
ALTER TABLE ONLY labels_images
	ADD CONSTRAINT labels_images_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);
ALTER TABLE ONLY masters_images
	ADD CONSTRAINT masters_images_fk_master_id FOREIGN KEY (master_id) REFERENCES master(id);
ALTER TABLE ONLY masters_images
	ADD CONSTRAINT masters_images_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);
ALTER TABLE ONLY releases_images
	ADD CONSTRAINT releases_images_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY releases_images
	ADD CONSTRAINT releases_images_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);
ALTER TABLE ONLY artists_images 
	ADD CONSTRAINT artists_images_fk_artist_id FOREIGN KEY (artist_id) REFERENCES artist(id);
ALTER TABLE ONLY artists_images
	ADD CONSTRAINT artists_images_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);

ALTER TABLE ONLY master_video
	ADD CONSTRAINT master_video_fk_master_id FOREIGN KEY (master_id) REFERENCES master(id);
ALTER TABLE ONLY master_video
	ADD CONSTRAINT master_video_fk_video_uri FOREIGN KEY (video_uri) REFERENCES video(uri);
ALTER TABLE ONLY release_video
	ADD CONSTRAINT release_video_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY release_video
	ADD CONSTRAINT release_video_fk_video_uri FOREIGN KEY (video_uri) REFERENCES video(uri);


-- indexes
CREATE INDEX releases_labels_idx_release_id ON releases_labels USING btree (release_id);
CREATE INDEX release_identfier_idx_release_id ON release_identifier USING btree (release_id);
CREATE INDEX releases_formats_idx_release_id ON releases_formats USING btree (release_id);
CREATE INDEX track_idx_release_id ON track USING btree (release_id);

CREATE INDEX masters_artists_idx_master_id ON masters_artists USING btree (master_id);
CREATE INDEX releases_artists_idx_release_id ON releases_artists USING btree (release_id);
CREATE INDEX tracks_artists_idx_track_id ON tracks_artists USING btree (track_id);
CREATE INDEX releases_extraartists_idx_release_id ON releases_extraartists USING btree (release_id);
CREATE INDEX tracks_extraartists_idx_track_id ON tracks_extraartists USING btree (track_id);

CREATE UNIQUE INDEX label_idx_lower_name ON label USING btree (lower(name));



-- finalize artist
-- there are some artists on errorous state where name (www-page) and api gives different entity
-- removing those gives us unique name index, we also include some special purpose artists which
-- are not included in XML export, last artist pointers that are not found in XML export updated
-- to point 'unknown artist'
DELETE FROM artist WHERE id = 455231;
DELETE FROM artist WHERE id = 1884533;
DELETE FROM artist WHERE id = 2159541;
DELETE FROM artist WHERE id = 2808461;
DELETE FROM artist WHERE id = 1360244;
DELETE FROM artist WHERE id = 1882549;
DELETE FROM artist WHERE id = 2443724;
DELETE FROM artist WHERE id = 2159540;
DELETE FROM artist WHERE id = 2036271;
DELETE FROM artist WHERE id = 1955085;
INSERT INTO artist(id, name) VALUES (194, 'various');
INSERT INTO artist(id, name) VALUES (355, 'unknown artist');
INSERT INTO artist(id, name) VALUES (118760, 'no artist');
CREATE UNIQUE INDEX artist_idx_lower_name ON artist USING btree (lower(name));
UPDATE releases_artists SET artist_id = 355 WHERE NOT EXISTS (SELECT id FROM artist WHERE id = releases_artists.artist_id);
UPDATE releases_extraartists SET artist_id = 355
	WHERE NOT role_name = ANY(array['Artwork By','Photography','Other','Executive Producer','Written By'])
	AND NOT EXISTS (SELECT id FROM artist WHERE id = releases_extraartists.artist_id);
UPDATE tracks_artists SET artist_id = 355 WHERE NOT EXISTS (SELECT id FROM artist WHERE id = tracks_artists.artist_id);
UPDATE tracks_extraartists SET artist_id = 355
	WHERE NOT role_name = ANY(array['Artwork By','Photography','Other','Executive Producer','Written By'])
	AND NOT EXISTS (SELECT id FROM artist WHERE id = tracks_extraartists.artist_id);


-- finalize releases_labels
-- function lower is used because otherwise over 38000 labels don't get they id's
UPDATE releases_labels SET label_id = label.id FROM label WHERE lower(releases_labels.label) = lower(label.name);
DELETE FROM releases_labels WHERE label_id ISNULL;
ALTER TABLE releases_labels DROP COLUMN label;
CREATE INDEX releases_labels_idx_label_id ON releases_labels USING btree(label_id);

