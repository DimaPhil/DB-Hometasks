DROP DATABASE IF EXISTS airline;
CREATE DATABASE airline;
\c airline;

CREATE TABLE Flights (
  FlightId INT NOT NULL,
  FlightTime TIMESTAMP DEFAULT '1970-01-01 00:00:01',
  PlaneId INT NOT NULL,
  ClosedByRequest BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (FlightId, PlaneId)
);

CREATE TABLE Seats (
  PlaneId INT NOT NULL,
  SeatNo INT NOT NULL,
  PRIMARY KEY (PlaneId, SeatNo)
);

CREATE TABLE Transaction (
  FlightId INT NOT NULL,
  PlaneId INT NOT NULL,
  SeatNo INT NOT NULL,
  PassportSeries INT DEFAULT NULL,
  PassportNo INT DEFAULT NULL,
  TransTime TIMESTAMP DEFAULT now(),
  TransType INT DEFAULT 0, -- 0 - бронирование, 1 - покупка
  FOREIGN KEY (FlightId, PlaneId) REFERENCES Flights,
  FOREIGN KEY (PlaneId, SeatNo) REFERENCES Seats
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  PRIMARY KEY (FlightId, PlaneId, SeatNo)
);

CREATE FUNCTION isBookingExpired(flightId INT, planeId INT, seatNo INT)
RETURNS BOOLEAN AS $BODY$
  DECLARE flightTime TIMESTAMP;
  DECLARE lastBookingUpdate TIMESTAMP;
  DECLARE isClosedByRequest BOOLEAN DEFAULT FALSE;
BEGIN
  SELECT (F.FlightTime, F.ClosedByRequest) INTO
    flightTime, isClosedByRequest
  FROM
    Flights as F
  WHERE
    F.FlightId = flightId AND
    F.PlaneId = planeId;

  SELECT T.TransTime INTO
    lastBookingUpdate
  FROM
    Transaction as T
  WHERE
    T.FlightId = flightId AND
    T.PlaneId = planeId AND
    T.SeatNo = seatNo AND
    T.TransType = 0;

  RETURN isClosedByRequest OR
         lastBookingUpdate IS NOT NULL AND lastBookingUpdate + INTERVAL '24 hours' < NOW() OR
         NOW() + INTERVAL '24 hours' > flightTime;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION updateBooking()
RETURNS TRIGGER AS $BODY$
  DECLARE flightId INT;
  DECLARE planeId INT;
  DECLARE seatNo INT;
BEGIN
  flightId := NEW.FlightId;
  planeId := NEW.PlaneId;
  seatNo := NEW.SeatNo;
  IF isBookingExpired(flightId, planeId, seatNo) THEN
    --Booking is expired, we can't update it
    DELETE FROM
      Transaction as T
    WHERE
      T.FlightId = flightId AND
      T.PlaneId = planeId AND
      T.SeatNo = seatNo AND
      T.TransType = 0;
    RETURN NEW;
  ELSE
    UPDATE
      Transaction as T
    SET 
      T.TransTime = now()
    WHERE
      T.FlightId = flightId AND
      T.PlaneId = planeId AND
      T.SeatNo = seatNo AND
      T.TransType = 0;
    RETURN NEW;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION buySeat()
RETURNS TRIGGER AS $BODY$
  DECLARE flightId INT;
  DECLARE planeId INT;
  DECLARE seatNo INT;
  DECLARE passportSeries INT;
  DECLARE passportNo INT;
  DECLARE flightTime TIMESTAMP;
  DECLARE isClosedByRequest BOOLEAN DEFAULT FALSE;
  DECLARE nowPassportSeries INT DEFAULT NULL;
  DECLARE nowPassportNo INT DEFAULT NULL;
  DECLARE transType INT DEFAULT NULL;
BEGIN
  flightId := NEW.FlightId;
  planeId := NEW.PlaneId;
  seatNo := NEW.SeatNo;
  passportSeries := NEW.PassportSeries;
  passportNo := NEW.PassportNo;
  SELECT (F.FlightTime, F.isClosedByRequest) INTO
    flightTime, isClosedByRequest
  FROM
    Flights as F
  WHERE
    F.FlightId = flightId AND
    F.PlaneId = planeId;

  IF NOT F.isClosedByRequest AND NOW() <= flightTime - INTERVAL '2 hours' THEN
    SELECT (T.PassportSeries, T.PassportNo, T.TransType) INTO
      nowPassportSeries, nowPassportNo, transType
    FROM
      Transaction as T
    WHERE
      T.FlightId = flightId AND
      T.PlaneId = planeId AND
      T.SeatNo = seatNo;
    IF (nowPassportSeries IS NULL AND 
        nowPassportNo IS NULL) OR
       (transType = 0 AND
        nowPassportSeries = passportSeries AND
        nowPassportNo = passportNo) OR
       (transType = 0 AND
        isBookingExpired(flightId, planeId, seatNo)) THEN
      DELETE FROM
        Transaction as T
      WHERE
        T.FlightId = flightId AND
        T.PlaneId = planeId AND
        T.SeatNo = seatNo;

      INSERT INTO Transaction
        (FlightId, PlaneId, SeatNo, PassportSeries, PassportNo, TransType)
      VALUES
        (flightId, planeId, seatNo, passportSeries, passportNo, 1);
      RETURN NEW;
    ELSE
      --seat it already bought or booked, can't buy it
      RETURN OLD;
    END IF;
  ELSE
    --bying is closed or it is too late
    RETURN OLD;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION bookSeat()
RETURNS TRIGGER AS $BODY$
  DECLARE flightId INT;
  DECLARE planeId INT;
  DECLARE seatNo INT;
  DECLARE passportSeries INT;
  DECLARE passportNo INT;
  DECLARE flightTime TIMESTAMP;
  DECLARE isClosedByRequest BOOLEAN DEFAULT FALSE;
  DECLARE nowPassportSeries INT DEFAULT NULL;
  DECLARE nowPassportNo INT DEFAULT NULL;
  DECLARE transType INT DEFAULT NULL;
BEGIN
  flightId := NEW.FlightId;
  planeId := NEW.PlaneId;
  seatNo := NEW.SeatNo;
  passportSeries := NEW.PassportSeries;
  passportNo := NEW.PassportNo;
  SELECT (F.FlightTime, F.isClosedByRequest) INTO
    flightTime, isClosedByRequest
  FROM
    Flights as F
  WHERE
    F.FlightId = flightId AND
    F.PlaneId = planeId;

  IF NOT F.isClosedByRequest AND NOW() <= flightTime - INTERVAL '24 hours' THEN
    SELECT (T.PassportSeries, T.PassportNo, T.TransType) INTO
      nowPassportSeries, nowPassportNo, transType
    FROM
      Transaction as T
    WHERE
      T.FlightId = flightId AND
      T.PlaneId = planeId AND
      T.SeatNo = seatNo;
    IF (nowPassportSeries IS NULL AND 
        nowPassportNo IS NULL) OR
       (transType = 0 AND
        isBookingExpired(flightId, planeId, seatNo)) THEN
      DELETE FROM
        Transaction as T
      WHERE
        T.FlightId = flightId AND
        T.PlaneId = planeId AND
        T.SeatNo = seatNo;

      INSERT INTO Transaction
        (FlightId, PlaneId, SeatNo, PassportSeries, PassportNo, TransType)
      VALUES
        (flightId, planeId, seatNo, passportSeries, passportNo, 0);
      RETURN NEW;
    ELSE
      --seat it already booked (maybe by yourself, but it doesn't matter), can't buy it
      RETURN OLD;
    END IF;
  ELSE
    --booking is closed or it is too late
    RETURN OLD;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER BuySeatTrigger
AFTER INSERT ON Transaction
FOR EACH ROW EXECUTE PROCEDURE buySeat();

CREATE TRIGGER BookSeatTrigger
AFTER INSERT ON Transaction
FOR EACH ROW EXECUTE PROCEDURE bookSeat();

CREATE TRIGGER UpdateBookingTrigger
AFTER UPDATE ON Transaction
FOR EACH ROW EXECUTE PROCEDURE updateBooking();
