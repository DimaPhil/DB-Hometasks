DROP DATABASE IF EXISTS CTD;
CREATE DATABASE ctd;
\c ctd;

CREATE TABLE Groups (
  GId SERIAL PRIMARY KEY,
  GName VARCHAR(10) UNIQUE
);

CREATE TABLE Student (
  SId SERIAL PRIMARY KEY,
  SName VARCHAR(50),
  GId INT REFERENCES Groups,
  UNIQUE (SId, GId)
);

CREATE TABLE Course (
  CId SERIAL PRIMARY KEY,
  CName VARCHAR(50) UNIQUE
);

CREATE TABLE Lecturer (
  LId SERIAL PRIMARY KEY,
  LName VARCHAR(50)
);

CREATE TABLE Plan (
  CId INT REFERENCES Course,
  GId INT REFERENCES Groups,
  LId INT REFERENCES Lecturer,
  PRIMARY KEY (CId, GId)
);

CREATE TABLE Mark (
  CId INT,
  GId INT,
  SId INT,
  Mark INT CHECK (Mark >= 0 AND Mark <= 100),
  FOREIGN KEY (CId, GId) REFERENCES Plan ON DELETE CASCADE,
  FOREIGN KEY (SId, GId) REFERENCES Student(SId, GId) ON DELETE CASCADE,
  PRIMARY KEY (CId, SId)
);

INSERT INTO Groups
  (GName) VALUES
  ('M3439'),
  ('M3438'),
  ('M3437'),
  ('M3436');

INSERT INTO Student
  (SName, GId) VALUES
  ('Дмитрий Филиппов', 1),
  ('Григорий Шовкопляс', 1),
  ('Илья Пересадин', 1),
  ('Никита Ященко', 2),
  ('Андрей Полин', 3),
  ('Сергей Патрикеев', 2),
  ('Замятин Евгений', 1);

INSERT INTO Course
  (CName) VALUES
  ('Математический анализ'),
  ('Базы данных'),
  ('Технологии Java'),
  ('Вычислительная геометрия');

INSERT INTO Lecturer
  (LName) VALUES
  ('Додонов Николай Юрьевич'),
  ('Кохась Константин Петрович'),
  ('Корнеев Георгий Александрович'),
  ('Ковалев Антон'),
  ('Маврин Павел');

INSERT INTO Plan
  (CId, GId, LId) VALUES
  (1, 1, 1),
  (1, 2, 2),
  (4, 2, 2),
  (2, 2, 3),
  (2, 1, 3),
  (3, 2, 3),
  (4, 3, 4),
  (4, 1, 5);

INSERT INTO Mark
  (CId, GId, SId, Mark) VALUES
  (1, 1, 1, 89),
  (3, 2, 4, 50),
  (1, 2, 4, 50),
  (2, 2, 4, 50),
  (4, 1, 2, 40);

CREATE VIEW
    Losers
AS
    SELECT
        S.SId, S.SName,
        (SELECT COUNT(*) FROM
            (SELECT * FROM
                Mark M
             WHERE 
                M.SId = S.SId AND M.Mark < 60
            ) as debts_info) as debts_count
    FROM
        Student S;

SELECT * INTO LoserT FROM Losers;

CREATE TABLE NewPoints (
  SId INT NOT NULL,
  SName VARCHAR(45),
  CId INT,
  Mark INT NOT NULL,
  PRIMARY KEY (SId, CId)
);

SELECT * FROM LoserT;

INSERT INTO NewPoints
  (SId, CId, Mark) VALUES
  (1, 4, 60),
  (1, 3, 45),
  (2, 3, 58),
  (2, 4, 70);

MERGE INTO LoserT LT
USING (SELECT * FROM NewPoints NP, Mark M) NPM
ON LT.SId = NPM.SId AND M.CId = NPM.CId
WHEN MATCHED THEN
    UPDATE SET LT.debts_count = 
        CASE 
            WHEN M.Mark < 60 AND NPM.Mark >= 60 THEN LT.debts_count - 1
            WHEN M.Mark >= 60 AND NPM.Mark < 60 THEN LT.debts_count + 1
            ELSE LT.debts_count
        END
WHEN NOT MATCHED THEN
    IF NPM.Mark < 60 THEN
        INSERT VALUES (NPM.SId, NPM.SName, 1);
    ELSE
        INSERT VALUES (NPM.SID, NPM.SName, 0);
    END IF;

SELECT * FROM LoserT;