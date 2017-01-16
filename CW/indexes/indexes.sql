CREATE INDEX ConcertDateIndex ON Concert USING HASH (concert_date);
CREATE INDEX ConcertCountryIndex ON Concert USING HASH (concert_country);
CREATE INDEX ConcertCityIndex ON Concert USING HASH (concert_city);
CREATE INDEX AccountCountryIndex ON Account USING HASH (country);
CREATE INDEX AccountCityIndex ON Account USING HASH (city);
CREATE INDEX BandFoundationIndex ON BAND USING HASH (found_year);
CREATE INDEX AlbumReleaseIndex ON Album USING HASH (release_date);

CREATE EXTENSION btree_gist;
CREATE INDEX BandNameIndex ON Band USING GIST (band_name);
CREATE INDEX AlbumNameIndex ON Album USING GIST (album_name);
CREATE INDEX TrackNameIndex ON Track USING GIST (track_name);
CREATE INDEX ConcertTitleIndex ON Concert USING GIST (title);

CREATE INDEX UserFullNameIndex ON Account USING BTREE (fname, lname);
CREATE INDEX ArtistFullNameIndex ON Artist USING BTREE (first_name, last_name);
