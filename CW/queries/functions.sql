CREATE OR REPLACE FUNCTION cancelConcert(concert_id INT)
RETURNS BOOLEAN AS $BODY$
DECLARE
  _isCanceled BOOLEAN;
BEGIN
  SELECT isCancelled
  INTO _isCanceled
  FROM Concert c
  WHERE c.concert_id = concert_id;

  IF _isCanceled THEN
    RAISE EXCEPTION 'Concert % is already cancelled', concert_id;
  ELSE
    UPDATE Concert c
    SET c.isCancelled = true
    WHERE c.concert_id = concert_id;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION userScrobbles(user_login VARCHAR(30))
RETURNS INT AS $BODY$
DECLARE
  scrobbles INT;
BEGIN
  SELECT COUNT(*) 
  INTO scrobbles
  FROM Scrobble s
  WHERE s.login = user_login;
  RETURN scrobbles;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trackScrobbles(tid INT)
RETURNS INT AS $BODY$
DECLARE
  scrobbles INT;
BEGIN
  SELECT COUNT(*) 
  INTO scrobbles
  FROM Scrobble s
  WHERE s.track_id = tid;
  RETURN scrobbles;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bandScrobbles(bid INT)
RETURNS INT AS $BODY$
DECLARE
  scrobbles INT;
BEGIN
  SELECT COUNT(*) 
  INTO scrobbles
  FROM (Scrobble 
       NATURAL JOIN Band
       NATURAL JOIN Track) sbt
  WHERE sbt.band_id = bid;
  RETURN scrobbles;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION topUserTracks(user_login VARCHAR(30))
RETURNS VARCHAR(100) AS $BODY$
DECLARE
  tracks VARCHAR(100);
BEGIN
  SELECT string_agg(track_name, ', ')
  INTO tracks
  FROM (SELECT DISTINCT 
            st.track_name,
            trackScrobbles(st.track_id) as scrobbles
        FROM (Scrobble NATURAL JOIN Track) st
        WHERE st.login = user_login
        GROUP BY st.track_id, st.track_name
        ORDER BY trackScrobbles(st.track_id) DESC
        LIMIT 3
        ) tmp;

  RETURN tracks;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION topBandTracks(bid INT)
RETURNS VARCHAR(100) AS $BODY$
DECLARE
  tracks VARCHAR(100);
BEGIN
  SELECT string_agg(track_name, ', ')
  INTO tracks
  FROM (SELECT DISTINCT 
            st.track_name,
            trackScrobbles(st.track_id) as scrobbles
        FROM (Scrobble NATURAL JOIN Track) st
        WHERE st.band_id = bid
        GROUP BY st.track_id, st.track_name
        ORDER BY trackScrobbles(st.track_id) DESC
        LIMIT 3
        ) tmp;

  RETURN tracks;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bestBand(user_login VARCHAR(30))
RETURNS VARCHAR(30) AS $BODY$
DECLARE
  band VARCHAR(30);
BEGIN
  SELECT band_name
  INTO band
  FROM (SELECT DISTINCT 
            stb.band_name,
            bandScrobbles(stb.band_id) as scrobbles
        FROM (Scrobble NATURAL JOIN Track NATURAL JOIN Band) stb
        WHERE stb.login = user_login
        GROUP BY stb.band_id, stb.band_name
        ORDER BY bandScrobbles(stb.band_id) DESC
        LIMIT 1
        ) tmp;

  RETURN band;
END;
$BODY$ LANGUAGE plpgsql;

