CREATE INDEX BandNameIndex ON Band USING BTREE (band_name);
CREATE INDEX AlbumNameIndex ON Album USING BTREE (album_name);
CREATE INDEX TrackNameIndex ON Track USING BTREE (track_name);
CREATE INDEX ConcertTitleIndex ON Concert USING BTREE (title, is_cancelled);
CREATE INDEX ArtistFullNameIndex ON Artist USING BTREE (first_name, last_name);
