CREATE INDEX LoginIndex ON Account USING HASH (login);
CREATE INDEX ConcertDateIndex ON Concert USING HASH (concert_date);
CREATE INDEX ConcertCityIndex ON Concert USING HASH (concert_city);
CREATE INDEX GenreIndex ON Genre USING HASH (genre);

CREATE EXTENSION btree_gist;
CREATE INDEX BandNameIndex ON Band USING GIST (band_name);
CREATE INDEX AlbumNameIndex ON Album USING GIST (album_name);
CREATE INDEX TrackNameIndex ON Track USING GIST (track_name);
CREATE INDEX ConcertTitleIndex ON Concert USING GIST (title);

CREATE INDEX ArtistFullNameIndex ON Artist USING BTREE (first_name, last_name);
CREATE INDEX BandGenreIndex ON BandGenre USING BTREE (band_id, genre);
