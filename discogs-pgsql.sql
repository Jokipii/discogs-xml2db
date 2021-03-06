﻿SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

CREATE SCHEMA discogs;

SET search_path = discogs;


-- Type for quality
CREATE TYPE quality AS ENUM (
	'Entirely Incorrect', 'Needs Vote', 'Needs Major Changes',
	'Needs Minor Changes', 'Correct','Complete and Correct'
);
-- Type for status
CREATE TYPE status AS ENUM ('Accepted', 'Draft', 'Deleted');
-- Type for image type
CREATE TYPE image_type AS ENUM ('primary', 'secondary');
--- Type for genre
CREATE TYPE genre AS ENUM (
	'Non-Music', 'Blues', 'Funk / Soul', 'Folk, World, & Country',
	'Rock', 'Classical', 'Brass & Military', 'Stage & Screen',
	'Latin', 'Hip Hop', 'Pop', 'Jazz', 'Reggae', 'Children''s',
	'Electronic'
);
-- Type for release_identifier type
CREATE TYPE identifier_type AS ENUM (
	'Matrix / Runout', 'Asin', 'Other', 'Barcode',
	'Rights Society', 'Label Code'
);
-- Type for format (types form www.discogs.com/help/formatslist with additional type 'Unknown')
CREATE TYPE format AS ENUM (
	'Vinyl', 'Acetate', 'Flexi-disc', 'Lathe Cut', 'Shellac', 'Pathé Disc', 'Edison Disc', 
	'Cylinder', 'CD', 'CDr', 'CDV', 'DVD', 'DVDr', 'HD DVD', 'HD DVD-R', 'Blu-ray', 
	'Blu-ray-R', '4-Track Cartridge', '8-Track Cartridge', 'Cassette', 'DAT', 'DCC', 
	'Microcassette', 'Reel-To-Reel', 'Betamax', 'VHS', 'Video 2000', 'Laserdisc', 
	'SelectaVision', 'VHD', 'Minidisc', 'MVD', 'UMD', 'Floppy Disk', 'File', 
	'Memory Stick', 'Hybrid', 'All Media', 'Box Set', 'Unknown'
);
-- Descriptions from www.discogs.com/help/formatslist
CREATE TYPE description AS ENUM (
	'LP', '16"', '12"', '11"', '10"', '9"', '8"', '7"', '6½"', '6"', '5½"', '5"', '4"', 
	'16 ⅔ RPM', '33 ⅓ RPM', '45 RPM', '78 RPM', '21cm', '25cm', '27cm', '29cm', '35cm', '50cm', '80 RPM', '90 RPM', 
	'1 ⅞ ips', '3 ¾ ips', '7 ½ ips', '15 ips', '30 ips', '⅛"', '¼"', '½"', '2 Minute', '4 Minute', 
	'Concert', 'Salon', 'Mini', 'Business Card', 'Shape', 'Minimax', 
	'CD-ROM', 'CDi', 'CD+G', 'HDCD', 'SACD', 'VCD', 'AVCD', 'SVCD', 'DVD-Audio', 'DVD-Data', 'DVD-Video', 
	'AAC', 'AIFC', 'AIFF', 'ALAC', 'FLAC', 'FLV', 'MP3', 'MPEG-4 Video', 'ogg-vorbis', 'SWF', 'WAV', 'WMA', 
	'WMV', 'MP3 Surround', '3.5"', '5.25"', 'DualDisc', 'DVDplus', 'VinylDisc ', 'Card Backed', 'Double Sided', 
	'Etched', 'Picture Disc', 'Single Sided', 'Album', 'Mini-Album', 'EP', 'Maxi-Single', 'Single', 'Compilation', 
	'Stereo', 'Mono', 'Quadraphonic', 'Ambisonic', 'Enhanced', 'Limited Edition', 'Mispress', 'Misprint', 'Reissue', 
	'Remastered', 'Repress', 'Test Pressing', 'Promo', 'White Label', 'Mixed', 'Partially Mixed', 
	'Unofficial Release', 'Partially Unofficial', 'Sampler', 'Copy Protected', 'Multichannel', 'NTSC', 'PAL', 'SECAM'
);


--- label
CREATE TABLE label (
	id integer,
	name text,
	contactinfo text,
	profile text,
	parent_label text,
	sublabels text[],
	urls text[],
	data_quality quality
);

-- master
-- final type for genres is genre[]
CREATE TABLE master (
	id integer,
	main_release integer,
	title text,
	year integer,
	notes text,
	genres text[],
	styles text[],
	data_quality quality
);

-- release
-- final type for genres is genre[]
CREATE TABLE release (
	id integer,
	status status,
	title text,
	country character varying(64),
	released character varying(32),
	notes text,
	genres text[],
	styles character varying(32)[],
	master_id integer,
	data_quality quality
);

-- label field is only for temporary use and dropped from final database after actual label_id field is set
CREATE TABLE releases_labels (
	release_id integer,
    label_id integer,
	label text,
	catno character varying(256)
);

CREATE TABLE release_identifier (
	release_id integer,
	type identifier_type,
	value text,
	description text
);

-- format_name is only for temporary use and dropped from final database after actual format field is set
CREATE TABLE releases_formats (
	release_id integer,
	qty integer,
	format_name character varying(32), 
    format format,
	descriptions character varying(32)[],
	text text
);

--- track
CREATE TABLE track (
	id serial,
	release_id integer,
	title text,
	duration character varying(12),
	position character varying(64)
);

--- artist
CREATE TABLE artist (
	id integer,
	name text,
	realname text,
	urls text[],
	namevariations text[],
	aliases text[],
	profile text,
	members text[],
	groups text[],
	data_quality quality
);

CREATE TABLE masters_artists (
	master_id integer,
	artist_id integer,
	artist_name text,
	anv text,
	join_relation text
);

CREATE TABLE releases_artists (
	release_id integer,
	artist_id integer,
	artist_name text,
	anv text,
	join_relation text
);

CREATE TABLE tracks_artists (
	track_id integer,
	artist_id integer,
	artist_name text,
	anv text,
	join_relation text
);

CREATE TABLE releases_extraartists (
	release_id integer,
	artist_id integer,
	artist_name text,
	anv text,
	role_name text,
	role_details text,
	tracks text
);

CREATE TABLE tracks_extraartists (
	track_id integer,
	artist_id integer,
	artist_name text,
	anv text,
	role_name text,
	role_details text
);

--- images
CREATE TABLE image (
	uri text,
	height integer,
	width integer,
	uri150 text
);

CREATE TABLE labels_images (
	label_id integer,
	type image_type,
	image_uri text
);

CREATE TABLE masters_images (
	master_id integer,
	type image_type,
	image_uri text
);

CREATE TABLE releases_images (
	release_id integer,
	type image_type,
	image_uri text
);

CREATE TABLE artists_images (
	artist_id integer,
	type image_type,
	image_uri text
);

-- video
CREATE TABLE video (
	uri text,
	duration integer,
	embed boolean,
	description text,
	title text
);

CREATE TABLE master_video (
	master_id integer,
	video_uri text
);

CREATE TABLE release_video (
	release_id integer,
	video_uri text
);



-- ACLs
REVOKE ALL ON SCHEMA discogs FROM PUBLIC;
REVOKE ALL ON SCHEMA discogs FROM postgres;
GRANT ALL ON SCHEMA discogs TO postgres;
GRANT ALL ON SCHEMA discogs TO PUBLIC;
