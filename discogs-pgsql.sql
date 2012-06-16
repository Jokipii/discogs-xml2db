--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

-- Type for quality
CREATE TYPE quality AS ENUM ('Entirely Incorrect', 'Needs Vote', 'Needs Major Changes', 'Needs Minor Changes', 'Correct', 'Complete and Correct');
-- Type for status
CREATE TYPE status AS ENUM ('Accepted', 'Draft', 'Deleted');

--
-- Name: artist; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE artist (
    id integer NOT NULL,
    name text NOT NULL,
    realname text,
    urls text[],
    namevariations text[],
    aliases text[],
    releases integer[],
    profile text,
    members text[],
    groups text[],
    data_quality quality
);


--
-- Name: artists_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE artists_images (
    image_uri text,
    artist_id integer
);


--
-- Name: format; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE format (
    name text NOT NULL
);


--
-- Name: genre; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE genre (
    id integer NOT NULL,
    name text,
    parent_genre integer,
    sub_genre integer
);


--
-- Name: image; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE image (
    height integer,
    width integer,
    type text,
    uri text NOT NULL,
    uri150 text
);


--
-- Name: label; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

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


--
-- Name: labels_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE labels_images (
    image_uri text,
    label_id integer
);


--
-- Name: release; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE release (
    id integer NOT NULL,
    status status,
    title text,
    country text,
    released text,
    notes text,
    genres text[],
    styles text[],
    master_id int,
    data_quality quality
);


--
-- Name: releases_artists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases_artists (
    id serial NOT NULL,
    artist_name text,
    anv text,
    join_relation text,
    artist_id integer,
    release_id integer
);


--
-- Name: releases_extraartists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases_extraartists (
    id serial NOT NULL,
    release_id integer,
    artist_id integer,
    artist_name text,
    anv text,
    role_name text,
    role_details text,
    tracks text
);


--
-- Name: releases_formats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases_formats (
    id serial NOT NULL,
    release_id integer,
    format_name text,
    qty integer,
    text text,
    descriptions text[]
);


--
-- Name: releases_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases_images (
    id serial NOT NULL,
    image_uri text,
    release_id integer
);


--
-- Name: releases_labels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases_labels (
    id serial NOT NULL,
    label text,
    release_id integer,
    catno text
);


--
-- Name: release_identifier; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE release_identifier (
    id serial NOT NULL,
    release_id integer,
    type text,
    value text,
    description text
);


--
-- Name: track; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE track (
    id integer,
    release_id integer,
    title text,
    duration text,
    "position" text
);


--
-- Name: tracks_artists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracks_artists (
    id serial NOT NULL,
    track_id integer NOT NULL,
    artist_id integer,
    artist_name text,
    anv text,
    join_relation text
);


--
-- Name: tracks_extraartists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracks_extraartists (
    id serial NOT NULL,
    track_id integer,
    artist_id integer,
    artist_name text,
    anv text,
    role_name text,
    role_details text
);


--
-- Name: master; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE master (
    id integer NOT NULL,
    title text,
    main_release integer NOT NULL,
    year int,
    notes text,
    genres text[],
    styles text[],
    data_quality quality
);


--
-- Name: masters_artists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE masters_artists (
    artist_name text,
    anv text,
    join_relation text,
    artist_id integer,
    master_id integer
);


--
-- Name: masters_images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE masters_images (
    image_uri text,
    master_id integer
);


--
-- Name: artist_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY artist
    ADD CONSTRAINT artist_pkey PRIMARY KEY (id);


--
-- Name: format_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY format
    ADD CONSTRAINT format_pkey PRIMARY KEY (name);


--
-- Name: genre_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY genre
    ADD CONSTRAINT genre_pkey PRIMARY KEY (id);


--
-- Name: image_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (uri);


--
-- Name: label_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY label
    ADD CONSTRAINT label_pkey PRIMARY KEY (id);


--
-- Name: release_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY release
    ADD CONSTRAINT release_pkey PRIMARY KEY (id);
ALTER TABLE ONLY release_identifier
    ADD CONSTRAINT release_identifier_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_artists
    ADD CONSTRAINT releases_artists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_extraartists
    ADD CONSTRAINT releases_extraartists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_formats
    ADD CONSTRAINT releases_formats_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_images
    ADD CONSTRAINT releases_images_pkey PRIMARY KEY (id);
ALTER TABLE ONLY releases_labels
    ADD CONSTRAINT releases_labels_pkey PRIMARY KEY (id);


--
-- Name: track_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY track
    ADD CONSTRAINT track_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tracks_artists
    ADD CONSTRAINT tracks_artists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tracks_extraartists
    ADD CONSTRAINT tracks_extraartists_pkey PRIMARY KEY (id);


--
-- Name: master_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY master
    ADD CONSTRAINT master_pkey PRIMARY KEY (id);


--
-- Name: artists_images_artist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY artists_images
    ADD CONSTRAINT artists_images_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES artist(id);


--
-- Name: artists_images_image_uri_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY artists_images
    ADD CONSTRAINT artists_images_image_uri_fkey FOREIGN KEY (image_uri) REFERENCES image(uri);


--
-- Name: labels_images_image_uri_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY labels_images
    ADD CONSTRAINT labels_images_image_uri_fkey FOREIGN KEY (image_uri) REFERENCES image(uri);


--
-- Name: labels_images_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY labels_images
    ADD CONSTRAINT labels_images_label_id_fkey FOREIGN KEY (label_id) REFERENCES label(id);


--
-- Name: releases_images_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases_images
    ADD CONSTRAINT releases_images_release_id_fkey FOREIGN KEY (release_id) REFERENCES release(id);


--
-- Name: releases_images_image_uri_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases_images
    ADD CONSTRAINT releases_images_image_uri_fkey FOREIGN KEY (image_uri) REFERENCES image(uri);


--
-- Name: masters_images_master_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY masters_images
    ADD CONSTRAINT masters_images_master_id_fkey FOREIGN KEY (master_id) REFERENCES master(id);

--
-- Name: masters_images_image_uri_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY masters_images
    ADD CONSTRAINT masters_images_image_uri_fkey FOREIGN KEY (image_uri) REFERENCES image(uri);


--
-- Name: release_identifier_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY release_identifier
    ADD CONSTRAINT release_identifier_release_id_fkey FOREIGN KEY (release_id) REFERENCES release(id);


--
-- Name: releases_artists_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases_artists
    ADD CONSTRAINT releases_artists_release_id_fkey FOREIGN KEY (release_id) REFERENCES release(id);


--
-- Name: releases_extraartists_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases_extraartists
    ADD CONSTRAINT releases_extraartists_release_id_fkey FOREIGN KEY (release_id) REFERENCES release(id);


--
-- Name: releases_labels_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases_labels
    ADD CONSTRAINT releases_labels_release_id_fkey FOREIGN KEY (release_id) REFERENCES release(id);


--
-- Name: releases_formats_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases_formats
    ADD CONSTRAINT releases_formats_release_id_fkey FOREIGN KEY (release_id) REFERENCES release(id);


--
-- Name: releases_formats_format_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases_formats
    ADD CONSTRAINT releases_formats_format_name_fkey FOREIGN KEY (format_name) REFERENCES format(name);


--
-- Name: track_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY track
    ADD CONSTRAINT track_release_id_fkey FOREIGN KEY (release_id) REFERENCES release(id);


--
-- Name: tracks_artists_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracks_artists
    ADD CONSTRAINT tracks_artists_track_id_fkey FOREIGN KEY (track_id) REFERENCES track(id);


--
-- Name: tracks_extraartists_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracks_extraartists
    ADD CONSTRAINT tracks_extraartists_track_id_fkey FOREIGN KEY (track_id) REFERENCES track(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

