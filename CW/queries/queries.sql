-- 1. Users and number of scrobbles they made in descending order of scrobbles, then in ascending order of login

SELECT login,
       userScrobbles(login) as scrobbles
FROM AccountScrobbles
GROUP BY login
ORDER BY scrobbles DESC, login;

-- 2. Track and number of users scrobbled it in descending order of scrobbles, in ascending order of band_name
-- (top 10 for simplicity)

SELECT band_name as band,
       album_name as album,
       track_name as track,
       trackScrobbles(track_id) as scrobbled
FROM Band 
     NATURAL JOIN Album 
     NATURAL JOIN Track
     NATURAL JOIN Scrobble
GROUP BY track_id, track_name, band_name, album_name
ORDER BY scrobbled DESC, band_name
LIMIT 10;

-- 3. User, Band and summary number of scrobbles for them ordered by login, then by scrobbles in descending order

SELECT login,
       band_name as band,
       bandScrobbles(band_id) as scrobbles
FROM Account
     NATURAL JOIN Band
     NATURAL JOIN Track
     NATURAL JOIN Scrobble
GROUP BY band_id, login
ORDER BY login, scrobbles DESC;

-- 4. Band and summary number of scrobbles for it ordered scrobbles in descending order, then by band_name

SELECT band_name as band,
       bandScrobbles(band_id) as scrobbles
FROM Band
     NATURAL JOIN Track
     NATURAL JOIN Scrobble
GROUP BY band_id
ORDER BY scrobbles DESC, band_name;

-- 5. Upcoming and not cancelled concerts (that are in a week)

SELECT title,
       concert_date as cdate,
       concert_country as country,
       concert_city as city,
       band_name as band
FROM ConcertInfo
WHERE NOT is_cancelled AND concert_date > NOW() AND concert_date - INTERVAL '168 hours' <= NOW();

-- 6. Recent not cancelled concerts in your city (no more than 1 week past)

SELECT title,
       concert_date as cdate,
       concert_country as country,
       concert_city as city,
       band_name as band
FROM ConcertInfo
WHERE NOT is_cancelled AND concert_date < NOW() AND concert_date + INTERVAL '168 hours' >= NOW();

-- 7. Top 3 tracks for user

SELECT login,
       topUserTracks(login) as top_tracks
FROM Account;

-- 8. Users that didn't scrobble anything

SELECT login
FROM Account a
WHERE NOT EXISTS (
    SELECT * FROM Scrobble s
    WHERE s.login = a.login
);

-- 9. Top 3 tracks for band

SELECT band_name as band,
       topBandTracks(band_id) as top_tracks
FROM Band;

-- 10. User and his favourite band (by scrobbles)

SELECT login,
       bestBand(login) as best_band
FROM Account;

-- 11. Pairs of bands that have common genre

SELECT b1.band_name as band1,
       b2.band_name as band2
FROM Band b1, Band b2
WHERE b1.band_id <> b2.band_id AND EXISTS (
        (SELECT bg.genre
         FROM BandGenre bg
         WHERE bg.band_id = b1.band_id)
        INTERSECT
        (SELECT bg.genre
         FROM BandGenre bg
         WHERE bg.band_id = b2.band_id)
      )
LIMIT 15;

-- 12. Pairs of bands such that first band genres is a subset of the second one genres
-- Big division

SELECT b1.band_name as band1, b2.band_name as band2
FROM Band b1, Band b2
WHERE b1.band_id <> b2.band_id AND NOT EXISTS (
  SELECT genre
  FROM BandGenre
  WHERE genre IN (
    SELECT bg.genre
    FROM BandGenre bg
    WHERE bg.band_id = b1.band_id
  ) AND genre NOT IN (
    SELECT bg.genre
    FROM BandGenre bg
    WHERE bg.band_id = b2.band_id
  )
)
LIMIT 5;

-- 13. Summary duration for album

SELECT band_name as band,
       album_name as album,
       SUM(duration) as duration
FROM Band 
     NATURAL JOIN Album
     NATURAL JOIN Track
GROUP BY album_id, band_name, album_name
ORDER BY band_name
LIMIT 15;

-- 14. 