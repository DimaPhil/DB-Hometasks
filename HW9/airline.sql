DROP DATABASE IF EXISTS airline;
CREATE DATABASE airline;
\c airline;

CREATE TABLE Flights (
  FlightId INT NOT NULL,
  FlightTime TIMESTAMP DEFAULT '1970-01-01 00:00:01',
  PlaneId INT NOT NULL,
  ClosedByRequest BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (FlightId)
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
  TransTime TIMESTAMP DEFAULT now(),
  TransType INT DEFAULT 0, -- 0 - бронирование, 1 - покупка
  FOREIGN KEY (FlightId) REFERENCES Flights,
  FOREIGN KEY (PlaneId, SeatNo) REFERENCES Seats
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  PRIMARY KEY (FlightId, SeatNo)
);

CREATE FUNCTION isReservationExpired(flightId INT, seatNo INT)
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
    F.FlightId = flightId;

  SELECT T.TransTime INTO
    lastBookingUpdate
  FROM
    Transaction as T
  WHERE
    T.FlightId = flightId AND
    T.SeatNo = seatNo AND
    T.TransType = 0;

  RETURN isClosedByRequest OR
         lastBookingUpdate IS NOT NULL AND lastBookingUpdate + INTERVAL '24 hours' < NOW() OR
         NOW() + INTERVAL '24 hours' > flightTime;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION FreeSeats(FlightId INT)
RETURNS TABLE (SeatNo INT) AS $BODY$
  DECLARE PlaneId INT DEFAULT NULL;
BEGIN
  SELECT (PlaneId) INTO
    PlaneId
  FROM 
    Flights as F
  WHERE
    F.FlightId = FlightId;

  RETURN QUERY
  SELECT
    S.SeatNo
  FROM
    Seats as S
  WHERE
    S.PlaneId = PlaneId
  EXCEPT
  SELECT
    T.SeatNo
  FROM 
    Transaction as T
  WHERE
    T.FlightId = FlightId AND
    T.PlaneId = PlaneId AND
    (T.TransType = 1 OR 
     (T.TransType = 0 AND NOT IsReservationExpired(T.FlightId, T.SeatNo)));
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION Reserve(FlightId INT, SeatNo INT)
RETURNS BOOLEAN AS $BODY$
  DECLARE flightTime TIMESTAMP;
  DECLARE PlaneId INT;
  DECLARE isClosedByRequest BOOLEAN DEFAULT FALSE;
  DECLARE transTime TIMESTAMP DEFAULT NULL;
  DECLARE transType INT DEFAULT NULL;
BEGIN
  SELECT (F.FlightTime, F.isClosedByRequest) INTO
    flightTime, isClosedByRequest
  FROM
    Flights as F
  WHERE
    F.FlightId = FlightId;

  IF NOT isClosedByRequest AND NOW() <= flightTime - INTERVAL '24 hours' THEN
    SELECT (T.PlaneId, T.TransTime, T.TransType) INTO
      PlaneId, transTime, transType
    FROM
      Transaction as T
    WHERE
      T.FlightId = FlightId AND
      T.SeatNo = SeatNo;
    IF (transTime IS NULL AND
        transType IS NULL) OR
       (transType = 0 AND
        isReservationExpired(FlightId, SeatNo)) THEN
      DELETE FROM
        Transaction as T
      WHERE
        T.FlightId = FlightId AND
        T.SeatNo = SeatNo;

      INSERT INTO Transaction
        (FlightId, PlaneId, SeatNo, TransTime, TransType)
      VALUES
        (FlightId, PlaneId, SeatNo, now(), 0);
      RETURN TRUE;
    ELSE
      --seat is already booked (maybe by yourself, but it doesn't matter), can't buy it
      RETURN FALSE;
    END IF;
  ELSE
    --booking is closed or it is too late
    RETURN FALSE;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION ExtendReservation(FlightId INT, SeatNo INT)
RETURNS BOOLEAN AS $BODY$
  DECLARE PlaneId INT;
BEGIN
  IF isBookingExpired(flightId, seatNo) THEN
    --Booking is expired, we can't update it
    DELETE FROM
      Transaction as T
    WHERE
      T.FlightId = FlightId AND
      T.SeatNo = SeatNo AND
      T.TransType = 0;
    RETURN FALSE;
  ELSE
    UPDATE
      Transaction as T
    SET 
      T.TransTime = now()
    WHERE
      T.FlightId = FlightId AND
      T.SeatNo = SeatNo AND
      T.TransType = 0;
    RETURN TRUE;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION BuyFree(FlightId INT, SeatNo INT)
RETURNS BOOLEAN AS $BODY$
  DECLARE PlaneId INT;
  DECLARE flightTime TIMESTAMP;
  DECLARE isClosedByRequest BOOLEAN DEFAULT FALSE;
  DECLARE transTime TIMESTAMP DEFAULT NULL;
  DECLARE transType INT DEFAULT NULL;
BEGIN
  SELECT (F.FlightTime, F.isClosedByRequest) INTO
    flightTime, isClosedByRequest
  FROM
    Flights as F
  WHERE
    F.FlightId = FlightId;

  IF NOT IsClosedByRequest AND NOW() <= flightTime - INTERVAL '2 hours' THEN
    SELECT (T.PlaneId, T.TransTime, T.TransType) INTO
      PlaneId, transTime, transType
    FROM
      Transaction as T
    WHERE
      T.FlightId = flightId AND
      T.SeatNo = seatNo;
    IF transTime IS NULL AND transType IS NULL THEN
      --Seat is free
      INSERT INTO Transaction
        (FlightId, PlaneId, SeatNo, TransTime, TransType)
      VALUES
        (FlightId, PlaneId, SeatNo, now(), 1);
      RETURN TRUE;
    ELSE
      --seat it already bought or booked, can't buy it
      RETURN FALSE;
    END IF;
  ELSE
    --bying is closed or it is too late
    RETURN FALSE;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION BuyReserved(FlightId INT, SeatNo INT)
RETURNS BOOLEAN AS $BODY$
  DECLARE PlaneId INT;
  DECLARE flightTime TIMESTAMP;
  DECLARE isClosedByRequest BOOLEAN DEFAULT FALSE;
  DECLARE transTime TIMESTAMP DEFAULT NULL;
  DECLARE transType INT DEFAULT NULL;
BEGIN
  SELECT (F.FlightTime, F.isClosedByRequest) INTO
    flightTime, isClosedByRequest
  FROM
    Flights as F
  WHERE
    F.FlightId = FlightId;

  IF NOT IsClosedByRequest AND NOW() <= flightTime - INTERVAL '2 hours' THEN
    SELECT (T.PlaneId, T.TransTime, T.TransType) INTO
      PlaneId, transTime, transType
    FROM
      Transaction as T
    WHERE
      T.FlightId = flightId AND
      T.SeatNo = seatNo;
    IF transType = 0 AND NOT isReservationExpired(FlightId, SeatNo) THEN
      --Seat was booked
      DELETE FROM
        Transaction as T
      WHERE
        T.FlightId = FlightId AND
        T.SeatNo = SeatNo;

      INSERT INTO Transaction
        (FlightId, PlaneId, SeatNo, TransTime, TransType)
      VALUES
        (FlightId, PlaneId, SeatNo, now(), 1);
      RETURN TRUE;
    ELSE
      --Seat is already bought or booked, can't buy it
      RETURN FALSE;
    END IF;
  ELSE
    --Bying is closed or it is too late
    RETURN FALSE;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION MayBuy(FId INT)
RETURNS BOOLEAN AS $BODY$
  DECLARE PId INT;
  DECLARE IsClosedByRequest BOOLEAN DEFAULT FALSE;
  DECLARE FTime TIMESTAMP DEFAULT NULL;
  DECLARE FreeSeatsCount INT DEFAULT NULL;
BEGIN
  SELECT (F.IsClosedByRequest, F.FTime, F.PlaneId)
  INTO IsClosedByRequest, FTime, PId
  FROM Flights F
  WHERE F.FlightId = FId;
  
  SELECT COUNT(*)
  INTO FreeSeatsCount
  FROM FreeSeats(FId);
  IF FreeSeatsCount == 0 OR 
     IsClosedByRequest OR NOW() > FTime - INTERVAL '2 hours' THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION MayReserve(FId INT)
RETURNS BOOLEAN AS $BODY$
  DECLARE PId INT;
  DECLARE IsClosedByRequest BOOLEAN DEFAULT FALSE;
  DECLARE FTime TIMESTAMP DEFAULT NULL;
  DECLARE FreeSeatsCount INT DEFAULT NULL;
BEGIN
  SELECT (F.IsClosedByRequest, F.FTime, F.PlaneId)
  INTO IsClosedByRequest, FTime, PId
  FROM Flights F
  WHERE F.FlightId = FId;
  
  SELECT COUNT(*)
  INTO FreeSeatsCount
  FROM FreeSeats(FId);
  IF FreeSeatsCount == 0 OR 
     IsClosedByRequest OR NOW() > FTime - INTERVAL '24 hours' THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION FreeSeatsCount(FId INT)
RETURNS INT AS $BODY$
  DECLARE FreeSeatsCount INT DEFAULT NULL;
BEGIN
  SELECT COUNT(*)
  INTO FreeSeatsCount
  FROM FreeSeats(FId);
  RETURN FreeSeatsCount;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION ReservedSeatsCount(FId INT)
RETURNS INT AS $BODY$
  DECLARE ReservedSeatsCount INT DEFAULT NULL;
BEGIN
  SELECT COUNT(*)
  INTO ReservedSeatsCount
  FROM (
    SELECT
      T.SeatNo
    FROM
      Transaction as T
    WHERE
      T.FlightId = FId AND
      T.TransType = 0
  ) as SUBQ;
  RETURN ReservedSeatsCount;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION BoughtSeatsCount(FId INT)
RETURNS INT AS $BODY$
  DECLARE BoughtSeatsCount INT DEFAULT NULL;
BEGIN
  SELECT COUNT(*)
  INTO BoughtSeatsCount
  FROM (
    SELECT
      T.SeatNo
    FROM
      Transaction as T
    WHERE
      T.FlightId = FId AND
      T.TransType = 1
  ) as SUBQ;
  RETURN BoughtSeatsCount;
END;
$BODY$ LANGUAGE plpgsql;

CREATE FUNCTION FlightStatistics()
RETURNS TABLE(FlightId INT, MayBuy BOOLEAN, MayReserve BOOLEAN, 
              FreeSeats INT, ReservedSeats INT, BoughtSeats INT) AS $BODY$
BEGIN
  RETURN QUERY
  SELECT F.FlightId, 
         MayBuy(F.FlightId) as MayBuy,
         MayReserve(F.FlightId) as MayReserve,
         FreeSeatsCount(F.FlightId) as FreeSeats,
         ReservedSeatsCount(F.FlightId) as ReservedSeats,
         BoughtSeatsCount(F.FlightId) as BoughtSeats
  FROM Flights F;
END;
$BODY$ LANGUAGE plpgsql;
