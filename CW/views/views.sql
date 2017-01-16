CREATE VIEW ConcertInfo AS (
    SELECT bc.title,
           bc.concert_country,
           bc.concert_city,
           bc.concert_date,
           bc.is_cancelled,
           bc.band_name
    FROM (Concert NATURAL JOIN Band) bc
    ORDER BY bc.concert_date
);

CREATE VIEW AccountScrobbles AS (
    SELECT asbat.login,
           asbat.band_name,
           asbat.album_name,
           asbat.track_name,
           asbat.scrobble_time
    FROM (Account 
          NATURAL JOIN Scrobble
          NATURAL JOIN Track
          NATURAL JOIN Album
          NATURAL JOIN Band
          ) asbat
    ORDER BY (asbat.login, asbat.scrobble_time)
);

CREATE VIEW BandListGenres AS (
    SELECT bg.band_name,
           string_agg(DISTINCT bg.genre, ', ') as genres
    FROM (BandGenre NATURAL JOIN Band) bg
    GROUP BY bg.band_name
);

CREATE VIEW BandListArtists AS (
    SELECT bca.band_name,
           string_agg(CONCAT(bca.first_name, ' ', bca.last_name), ', ') as artists
    FROM (Band NATURAL JOIN Contract NATURAL JOIN Artist) bca
    GROUP BY bca.band_name
);
