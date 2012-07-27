SET search_path = discogs;



-- Because we havent enforced contraints when we added data in database we need some clearing here
ALTER TABLE image ADD COLUMN id serial;
ALTER TABLE labels_images ADD COLUMN id serial;
ALTER TABLE artists_images ADD COLUMN id serial;
ALTER TABLE masters_images ADD COLUMN id serial;
ALTER TABLE releases_images ADD COLUMN id serial;

WITH orig AS (SELECT uri, min(id) FROM image GROUP BY uri HAVING count(id) > 1)
DELETE FROM image USING orig WHERE image.uri = orig.uri AND image.id <> orig.min;

WITH orig AS (SELECT image_uri, min(id) FROM labels_images GROUP BY image_uri HAVING count(id) > 1)
DELETE FROM labels_images USING orig WHERE labels_images.image_uri = orig.image_uri AND labels_images.id <> orig.min;

WITH orig AS (SELECT image_uri, min(id) FROM artists_images GROUP BY image_uri HAVING count(id) > 1)
DELETE FROM artists_images USING orig WHERE artists_images.image_uri = orig.image_uri AND artists_images.id <> orig.min;

WITH orig AS (SELECT image_uri, min(id) FROM masters_images GROUP BY image_uri HAVING count(id) > 1)
DELETE FROM masters_images USING orig WHERE masters_images.image_uri = orig.image_uri AND masters_images.id <> orig.min;

WITH orig AS (SELECT image_uri, min(id) FROM releases_images GROUP BY image_uri HAVING count(id) > 1)
DELETE FROM releases_images USING orig WHERE releases_images.image_uri = orig.image_uri AND releases_images.id <> orig.min;

ALTER TABLE image DROP COLUMN id;
ALTER TABLE labels_images DROP COLUMN id;
ALTER TABLE artists_images DROP COLUMN id;
ALTER TABLE masters_images DROP COLUMN id;
ALTER TABLE releases_images DROP COLUMN id;



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



--- foreign keys
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



--- indexes
CREATE INDEX releases_labels_idx_release_id ON releases_labels USING btree (release_id);
CREATE INDEX release_identfier_idx_release_id ON release_identifier USING btree (release_id);
CREATE INDEX releases_formats_idx_release_id ON releases_formats USING btree (release_id);
CREATE INDEX track_idx_release_id ON track USING btree (release_id);

CREATE INDEX masters_artists_idx_master_id ON masters_artists USING btree (master_id);
CREATE INDEX releases_artists_idx_release_id ON releases_artists USING btree (release_id);
CREATE INDEX tracks_artists_idx_track_id ON tracks_artists USING btree (track_id);
CREATE INDEX releases_extraartists_idx_release_id ON releases_extraartists USING btree (release_id);
CREATE INDEX tracks_extraartists_idx_track_id ON tracks_extraartists USING btree (track_id);

