DROP DATABASE IF EXISTS lastfm;
CREATE DATABASE lastfm;
\c lastfm;

CREATE TABLE Account (
    login VARCHAR(30) NOT NULL,
    password_hash VARCHAR(30) NOT NULL,
    fname VARCHAR(30) NOT NULL CHECK (SUBSTRING(fname FROM 1 FOR 1) != LOWER(SUBSTRING(fname FROM 1 FOR 1))),
    lname VARCHAR(30) NOT NULL CHECK (SUBSTRING(lname FROM 1 FOR 1) != LOWER(SUBSTRING(lname FROM 1 FOR 1))),
    country VARCHAR(30) DEFAULT 'Russia',
    city VARCHAR(30) DEFAULT 'St. Petersburg',
    PRIMARY KEY(login),
    UNIQUE (password_hash)
);

CREATE TABLE Band (
    band_id INT NOT NULL,
    band_name VARCHAR(30) NOT NULL,
    found_year INT NOT NULL CHECK (found_year >= 1900 AND found_year <= EXTRACT (YEAR FROM NOW())),
    PRIMARY KEY (band_id)
);

CREATE TABLE Album (
    album_id INT NOT NULL,
    album_name VARCHAR(30) NOT NULL,
    release_date DATE NOT NULL,
    band_id INT NOT NULL,
    PRIMARY KEY (album_id),
    FOREIGN KEY (band_id) REFERENCES Band ON DELETE CASCADE
);

CREATE TABLE Track (
    track_id INT NOT NULL,
    track_name VARCHAR(30) NOT NULL,
    duration INTERVAL NOT NULL CHECK (duration > '0:0:0'),
    album_id INT NOT NULL,
    band_id INT NOT NULL,
    PRIMARY KEY (track_id),
    FOREIGN KEY (album_id) REFERENCES Album ON DELETE CASCADE,
    FOREIGN KEY (band_id) REFERENCES Band ON DELETE CASCADE
);

CREATE TABLE Scrobble (
    scrobble_time TIMESTAMP NOT NULL,
    login VARCHAR(30) NOT NULL,
    track_id INT NOT NULL,
    PRIMARY KEY (scrobble_time, login),
    FOREIGN KEY (login) REFERENCES Account ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES Track ON DELETE CASCADE
);

CREATE TABLE Artist (
    artist_id INT NOT NULL,
    first_name VARCHAR(30) NOT NULL CHECK (SUBSTRING(first_name FROM 1 FOR 1) != LOWER(SUBSTRING(first_name FROM 1 FOR 1))),
    last_name VARCHAR(30) NOT NULL CHECK (SUBSTRING(last_name FROM 1 FOR 1) != LOWER(SUBSTRING(last_name FROM 1 FOR 1))),
    birthday DATE NOT NULL CHECK (birthday < NOW()),
    death DATE CHECK (death IS NULL OR birthday < death),
    PRIMARY KEY(artist_id)
);

CREATE TABLE Contract (
    band_id INT NOT NULL,
    artist_id INT NOT NULL,
    PRIMARY KEY (band_id, artist_id),
    FOREIGN KEY (band_id) REFERENCES Band ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES Artist ON DELETE CASCADE
);

CREATE TABLE Concert (
    concert_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    concert_date DATE NOT NULL,
    concert_country VARCHAR(30) NOT NULL,
    concert_city VARCHAR(30) NOT NULL,
    is_cancelled BOOLEAN DEFAULT FALSE,
    band_id INT NOT NULL,
    PRIMARY KEY (concert_id),
    FOREIGN KEY (band_id) REFERENCES Band ON DELETE CASCADE 
);

CREATE TABLE Genre (
    genre VARCHAR(30) NOT NULL,
    PRIMARY KEY (genre)
);

CREATE TABLE BandGenre (
    band_id INT NOT NULL,
    genre VARCHAR(30) NOT NULL,
    PRIMARY KEY (band_id, genre),
    FOREIGN KEY (band_id) REFERENCES Band ON DELETE CASCADE,
    FOREIGN KEY (genre) REFERENCES Genre ON DELETE CASCADE
);
