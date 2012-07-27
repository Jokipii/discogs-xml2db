SET client_encoding = 'UTF8';
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
	'Entirely Incorrect',
	'Needs Vote',
	'Needs Major Changes',
	'Needs Minor Changes',
	'Correct',
	'Complete and Correct');
-- Type for status
CREATE TYPE status AS ENUM ('Accepted', 'Draft', 'Deleted');
-- Type for image type
CREATE TYPE image_type AS ENUM ('primary', 'secondary');
--- Type for genre
CREATE TYPE genre AS ENUM (
	'Non-Music',
	'Blues',
	'Funk / Soul',
	'Folk, World, & Country',
	'Rock',
	'Classical',
	'Brass & Military',
	'Stage & Screen',
	'Latin',
	'Hip Hop',
	'Pop',
	'Jazz',
	'Reggae',
	'Children''s',
	'Electronic'
);
-- Type for release_identifier type
CREATE TYPE identifier_type AS ENUM (
	'Matrix / Runout',
	'Asin',
	'Other',
	'Barcode',
	'Rights Society',
	'Label Code'
);



--- label
CREATE TABLE label (
	id integer NOT NULL,
	name text NOT NULL,
	contactinfo text,
	profile text,
	parent_label text,
	sublabels text[],
	urls text[],
	data_quality quality
);

-- master
CREATE TABLE master (
	id integer NOT NULL,
	main_release integer NOT NULL,
	title text,
	year integer,
	notes text,
	genres text[],
	styles text[],
	data_quality quality
);

--- style
CREATE TABLE style (
	id serial NOT NULL,
	name character varying(32) NOT NULL
);

--- format
CREATE TABLE format (
	id serial NOT NULL,
	name character varying(32) NOT NULL
);

--- release
CREATE TABLE release (
	id integer NOT NULL,
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

CREATE TABLE releases_labels (
	id serial NOT NULL,
	release_id integer NOT NULL,
	label text,
	catno character varying(256)
);

CREATE TABLE release_identifier (
	id serial NOT NULL,
	release_id integer NOT NULL,
	type identifier_type,
	value text,
	description text
);

CREATE TABLE releases_formats (
	id serial NOT NULL,
	release_id integer NOT NULL,
	qty integer,
	format_name character varying(32),
	descriptions character varying(32)[],
	text text
);

--- track
CREATE TABLE track (
	id serial NOT NULL,
	release_id integer NOT NULL,
	title text,
	duration character varying(12),
	position character varying(64)
);

--- artist
CREATE TABLE artist (
	id integer NOT NULL,
	name text NOT NULL,
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
	id serial NOT NULL,
	master_id integer NOT NULL,
	artist_id integer,
	artist_name text,
	anv text,
	join_relation text
);

CREATE TABLE releases_artists (
	id serial NOT NULL,
	release_id integer NOT NULL,
	artist_id integer,
	artist_name text,
	anv text,
	join_relation text
);

CREATE TABLE tracks_artists (
	id serial NOT NULL,
	track_id integer NOT NULL,
	artist_id integer,
	artist_name text,
	anv text,
	join_relation text
);

CREATE TABLE releases_extraartists (
	id serial NOT NULL,
	release_id integer NOT NULL,
	artist_id integer,
	artist_name text,
	anv text,
	role_name text,
	role_details text,
	tracks text
);

CREATE TABLE tracks_extraartists (
	id serial NOT NULL,
	track_id integer NOT NULL,
	artist_id integer,
	artist_name text,
	anv text,
	role_name text,
	role_details text
);

--- image
CREATE TABLE image (
	id serial NOT NULL,
	uri text NOT NULL,
	height integer,
	width integer,
	type image_type,
	uri150 text
);

CREATE TABLE labels_images (
	id serial NOT NULL,
	label_id integer NOT NULL,
	image_uri text NOT NULL
);

CREATE TABLE masters_images (
	id serial NOT NULL,
	master_id integer NOT NULL,
	image_uri text NOT NULL
);

CREATE TABLE releases_images (
	id serial NOT NULL,
	release_id integer NOT NULL,
	image_uri text NOT NULL
);

CREATE TABLE artists_images (
	id serial NOT NULL,
	artist_id integer NOT NULL,
	image_uri text NOT NULL
);

-- video
CREATE TABLE video (
	id serial NOT NULL,
	uri text NOT NULL,
	duration integer,
	embed boolean,
	description text,
	title text
);

CREATE TABLE master_video (
	id serial NOT NULL,
	master_id integer NOT NULL,
	video_uri text NOT NULL
);

CREATE TABLE release_video (
	id serial NOT NULL,
	release_id integer NOT NULL,
	video_uri text NOT NULL
);



-- ACLs
REVOKE ALL ON SCHEMA discogs FROM PUBLIC;
REVOKE ALL ON SCHEMA discogs FROM postgres;
GRANT ALL ON SCHEMA discogs TO postgres;
GRANT ALL ON SCHEMA discogs TO PUBLIC;
