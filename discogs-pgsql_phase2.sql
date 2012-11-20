SET search_path = discogs;


-- Because we havent enforced contraints when we added data in database we need to do some clearing here
SELECT DISTINCT * INTO label_image FROM labels_images;
SELECT DISTINCT * INTO artist_image FROM artists_images;
SELECT DISTINCT * INTO master_image FROM masters_images;
SELECT DISTINCT * INTO release_image FROM releases_images;
SELECT DISTINCT * INTO images FROM image;
DROP TABLE artists_images;
DROP TABLE labels_images;
DROP TABLE masters_images;
DROP TABLE releases_images;
DROP TABLE image;
ALTER TABLE images RENAME TO image;

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
UPDATE releases_formats SET text = format_name||' '||text, format_name='Unknown' WHERE format_name <> ALL(array[
	'Vinyl', 'Acetate', 'Flexi-disc', 'Lathe Cut', 'Shellac', 'Pathé Disc', 'Edison Disc', 
	'Cylinder', 'CD', 'CDr', 'CDV', 'DVD', 'DVDr', 'HD DVD', 'HD DVD-R', 'Blu-ray', 
	'Blu-ray-R', '4-Track Cartridge', '8-Track Cartridge', 'Cassette', 'DAT', 'DCC', 
	'Microcassette', 'Reel-To-Reel', 'Betamax', 'VHS', 'Video 2000', 'Laserdisc', 
	'SelectaVision', 'VHD', 'Minidisc', 'MVD', 'UMD', 'Floppy Disk', 'File', 
	'Memory Stick', 'Hybrid', 'All Media', 'Box Set'
]);
UPDATE releases_formats SET format = format_name::format;
ALTER TABLE releases_formats DROP COLUMN format_name;


-- id fields for speed reasons they are not used in import time
ALTER TABLE releases_labels ADD COLUMN id serial NOT NULL;
ALTER TABLE release_identifier ADD COLUMN id serial NOT NULL;
ALTER TABLE releases_formats ADD COLUMN id serial NOT NULL;
ALTER TABLE masters_artists ADD COLUMN id serial NOT NULL;
ALTER TABLE releases_artists ADD COLUMN id serial NOT NULL;
ALTER TABLE tracks_artists ADD COLUMN id serial NOT NULL;
ALTER TABLE releases_extraartists ADD COLUMN id serial NOT NULL;
ALTER TABLE tracks_extraartists ADD COLUMN id serial NOT NULL;

-- set not null constraints
ALTER TABLE label ALTER COLUMN id SET NOT NULL;
ALTER TABLE master ALTER COLUMN id SET NOT NULL;
ALTER TABLE release ALTER COLUMN id SET NOT NULL;
ALTER TABLE track ALTER COLUMN id SET NOT NULL;
ALTER TABLE artist ALTER COLUMN id SET NOT NULL;



-- primary keys
ALTER TABLE ONLY label ADD CONSTRAINT label_pkey PRIMARY KEY (id);
ALTER TABLE ONLY master ADD CONSTRAINT master_pkey PRIMARY KEY (id);

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
ALTER TABLE ONLY label_image ADD CONSTRAINT label_image_pkey PRIMARY KEY (label_id, image_uri);
ALTER TABLE ONLY master_image ADD CONSTRAINT master_image_pkey PRIMARY KEY (master_id, image_uri);
ALTER TABLE ONLY release_image ADD CONSTRAINT release_image_pkey PRIMARY KEY (release_id, image_uri);
ALTER TABLE ONLY artist_image ADD CONSTRAINT artist_image_pkey PRIMARY KEY (artist_id, image_uri);

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

ALTER TABLE ONLY label_image
	ADD CONSTRAINT label_image_fk_label_id FOREIGN KEY (label_id) REFERENCES label(id);
ALTER TABLE ONLY label_image
	ADD CONSTRAINT label_image_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);
ALTER TABLE ONLY master_image
	ADD CONSTRAINT master_image_fk_master_id FOREIGN KEY (master_id) REFERENCES master(id);
ALTER TABLE ONLY master_image
	ADD CONSTRAINT master_image_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);
ALTER TABLE ONLY release_image
	ADD CONSTRAINT release_image_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY release_image
	ADD CONSTRAINT release_image_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);
ALTER TABLE ONLY artist_image
	ADD CONSTRAINT artist_image_fk_artist_id FOREIGN KEY (artist_id) REFERENCES artist(id);
ALTER TABLE ONLY artist_image
	ADD CONSTRAINT artist_image_fk_image_uri FOREIGN KEY (image_uri) REFERENCES image(uri);

ALTER TABLE ONLY master_video
	ADD CONSTRAINT master_video_fk_master_id FOREIGN KEY (master_id) REFERENCES master(id);
ALTER TABLE ONLY master_video
	ADD CONSTRAINT master_video_fk_video_uri FOREIGN KEY (video_uri) REFERENCES video(uri);
ALTER TABLE ONLY release_video
	ADD CONSTRAINT release_video_fk_release_id FOREIGN KEY (release_id) REFERENCES release(id);
ALTER TABLE ONLY release_video
	ADD CONSTRAINT release_video_fk_video_uri FOREIGN KEY (video_uri) REFERENCES video(uri);

ALTER TABLE releases_labels
	ADD CONSTRAINT releases_labels_fk_label_id FOREIGN KEY (label_id) REFERENCES label(id);

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
-- removing those gives us unique name index
DELETE FROM artist WHERE id = ANY(ARRAY[455231,1884533,2159541,2808461,1360244,1882549,2443724,2159540,2036271,1955085])
-- unfortunately problem is even worse than last time
-- xml 20121001 contains more errorous entries even problem is reported to Discogs maintenance last time
/*
-- here is queries that find those
SELECT lower(name) FROM artist GROUP BY lower(name) HAVING count(id) > 1;
SELECT * FROM artist WHERE lower(name) = ANY(ARRAY['3 doors down','afroman','atc','bicep',
	'bob leaper','city high','craig david','crossover','destiny''s child','dido','eve','five',
	'gabrielle','gorgoroth','human nature','i-f','incubus','jamiroquai','jennifer lopez','jessica simpson',
	'joanne','joy enriquez','kurupt','leah haywood','lou bega','mandy moore','mya','nelly furtado',
	'nikki webster','outkast','pink','r-zone','ricky martin','ronan keating','s club 7','sara','selwyn',
	'something for kate','stella one eleven','u2','vanessa amorosi','weezer','westlife','ϟ†nϟ']) ORDER BY name;
SELECT * FROM artist WHERE id = ANY(ARRAY[2937013,2844767,2844786,2844765,2883709,2844772,2844776,2940656,2844766,
2844774,2844792,2844791,2844796,2940659,2844784,2940658,2844801,2844788,2844789,2844781,2844785,2844800,2844779,
2844773,2844799,2844770,2844775,2844787,2844793,2844790,2844795,2937014,2844768,2844802,2844782,2844780,2844798,
2844769,2844797,2844783,2844771,2844778,2844794,2940657]);
*/
-- and remove errorous entries
DELETE FROM artist WHERE id = ANY(ARRAY[2937013,2844767,2844786,2844765,2883709,2844772,2844776,2940656,2844766,
2844774,2844792,2844791,2844796,2940659,2844784,2940658,2844801,2844788,2844789,2844781,2844785,2844800,2844779,
2844773,2844799,2844770,2844775,2844787,2844793,2844790,2844795,2937014,2844768,2844802,2844782,2844780,2844798,
2844769,2844797,2844783,2844771,2844778,2844794,2940657]);

-- we also include some special purpose artists which are not included in XML export
INSERT INTO artist(id, name) VALUES (194, 'Various');
INSERT INTO artist(id, name) VALUES (355, 'Unknown Artist');
INSERT INTO artist(id, name) VALUES (118760, 'No Artist');
-- and now we can create index
CREATE UNIQUE INDEX artist_idx_lower_name ON artist USING btree (lower(name));

-- last artist pointers that are not found in XML export updated to point 'unknown artist'
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

-- set NULLs on fields that have empty strings
UPDATE releases_extraartists SET tracks = NULL WHERE tracks = '';
UPDATE releases_extraartists SET anv = NULL WHERE anv = '';
UPDATE releases_artists SET anv = NULL WHERE anv = '';
UPDATE releases_artists SET join_relation = NULL WHERE join_relation = '';
UPDATE release_identifier SET description = NULL WHERE description = '';
UPDATE releases_formats SET text = NULL WHERE text = '';
UPDATE track SET duration = NULL WHERE duration = '';
UPDATE track SET position = NULL WHERE position = '';
UPDATE tracks_artists SET anv = NULL WHERE anv = '';
UPDATE tracks_artists SET join_relation = NULL WHERE join_relation = '';
UPDATE tracks_extraartists SET anv = NULL WHERE anv = '';
UPDATE video SET description = NULL WHERE description = '';
UPDATE release SET notes = NULL WHERE notes = '';
UPDATE masters_artists SET anv = NULL WHERE anv = '';
UPDATE masters_artists SET join_relation = NULL WHERE join_relation = '';
UPDATE master SET notes = NULL WHERE notes = '';
UPDATE label SET contactinfo = NULL WHERE contactinfo = '';
UPDATE label SET profile = NULL WHERE profile = '';
UPDATE label SET parent_label = NULL WHERE parent_label = '';
UPDATE artist SET profile = NULL WHERE profile = '';
