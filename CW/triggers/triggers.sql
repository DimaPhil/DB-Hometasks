-- Trigger to check that album release year goes not earlier than the foundation year of the band

CREATE OR REPLACE FUNCTION checkAlbumIsAfterFoundation()
    RETURNS TRIGGER AS $BODY$
DECLARE
    foundation_year INT;
BEGIN
    SELECT found_year
    INTO foundation_year
    FROM Band band
    WHERE band.band_id = NEW.band_id;
    
    IF foundation_year <= EXTRACT (YEAR FROM NEW.release_date) THEN
        RETURN NEW;
    ELSE
        RETURN NULL;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER CheckAlbumIsAfterFoundation
BEFORE INSERT OR UPDATE ON Album
FOR EACH ROW EXECUTE PROCEDURE checkAlbumIsAfterFoundation();

-- Trigger to check that concert date year goes not earlier than the foundation year of the band

CREATE OR REPLACE FUNCTION checkConcertIsAfterFoundation()
    RETURNS TRIGGER AS $BODY$
DECLARE
    foundation_year INT;
BEGIN
    SELECT found_year
    INTO foundation_year
    FROM Band band
    WHERE band.band_id = NEW.band_id;
    
    IF foundation_year <= EXTRACT (YEAR FROM NEW.concert_date) THEN
        RETURN NEW;
    ELSE
        RETURN NULL;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER CheckConcertIsAfterFoundation
BEFORE INSERT OR UPDATE ON Concert
FOR EACH ROW EXECUTE PROCEDURE checkConcertIsAfterFoundation();

-- Trigger to check whether password hash is correct, i.e. it contains only small of capital English letters and digits

CREATE OR REPLACE FUNCTION passwordHashCheck()
    RETURNS TRIGGER AS $BODY$
BEGIN
    IF NEW.password_hash ~ '[a-z|A-Z|0-9]+' THEN
        RETURN NEW;
    ELSE
        RETURN NULL;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER PasswordHashCheck
BEFORE INSERT OR UPDATE ON Account
FOR EACH ROW EXECUTE PROCEDURE passwordHashCheck();

-- ActiveUsers - table containing users and their total number of scrobbles if it is at least 10

SELECT accs.login, 
       COUNT(accs.scrobble_time) as scrobbles
INTO ActiveUsers
FROM AccountScrobbles accs
GROUP BY accs.login
HAVING COUNT(accs.scrobble_time) >= 10;

-- Trigger for updating ActiveUsers after inserting scrobble

CREATE OR REPLACE FUNCTION updateActiveUsers()
    RETURNS TRIGGER AS $BODY$
DECLARE
    scrobbles_count INT DEFAULT 0;
    user_login VARCHAR(30) DEFAULT NULL;
BEGIN
    SELECT COUNT(*) INTO scrobbles_count
    FROM Scrobble scrobble
    WHERE scrobble.login = NEW.login;

    SELECT login INTO user_login
    FROM ActiveUsers
    WHERE login = NEW.login;

    IF scrobbles_count >= 10 AND user_login IS NULL THEN
        INSERT INTO ActiveUsers
            (login, scrobbles)
        VALUES
            (NEW.login, scrobbles_count);
    END IF;
    RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER ActiveUsersUpdate
AFTER INSERT ON Scrobble
FOR EACH ROW EXECUTE PROCEDURE updateActiveUsers()
