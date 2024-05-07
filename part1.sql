set datestyle = 'ISO, DMY'

----------------------------------------------------------------------------------------------
--                           creating a database and filling it                           --
----------------------------------------------------------------------------------------------
--DROP SCHEMA public CASCADE;CREATE SCHEMA public;

-----------------------------------------------
--                  Peers                    --
-----------------------------------------------
CREATE TABLE IF NOT EXISTS Peers (
   Nickname VARCHAR PRIMARY KEY NOT NULL,
    Birthday DATE
);

COPY Peers FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/peers.csv' DELIMITER ';' CSV HEADER;
 /*    insert into Peers values('Wolf', '1990-02-04');
   insert into Peers values('Sprat_eater', '1999-02-05');
   insert into Peers values('Near_Muslim', '1980-12-10');
*/ 
-----------------------------------------------
--                  TASKS                    --
-----------------------------------------------
CREATE TABLE IF NOT EXISTS Tasks(
     Title VARCHAR PRIMARY KEY,
     parent_task VARCHAR,
     max_XP INTEGER,
    FOREIGN KEY (parent_task) REFERENCES Tasks(Title)
);

COPY tasks FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/tasks.csv' DELIMITER ';' CSV HEADER;
/* 
    insert into Tasks values('CPP1', null, 300);
    insert into Tasks values('CPP2', 'CPP1', 400);
    insert into Tasks values('A1', null, 300);
    insert into Tasks values('A2', 'A1', 400);
    insert into Tasks values('SQL1', null, 1500);
    insert into Tasks values('SQL2', 'SQL1', 500);
    insert into Tasks values('SQL3', 'SQL2', 600);
    */
-----------------------------------------------
--                  Checks                  --
-----------------------------------------------
CREATE TYPE CheckStatus AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE IF NOT EXISTS Checks(
    ID INTEGER PRIMARY KEY,
    Peer VARCHAR,
    Task VARCHAR,
    "Date" DATE,
   FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
    FOREIGN KEY (Task) REFERENCES Tasks(Title)
);
COPY Checks FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/checks.csv' DELIMITER ';' CSV HEADER;
/*
   INSERT INTO Checks (Peer, Task, "Date") VALUES ('Wolf', 'CPP1', '2022-12-01');
   INSERT INTO Checks (Peer, Task, "Date") VALUES ('Sprat_eater', 'A2', CURRENT_DATE);
   INSERT INTO Checks (Peer, Task, "Date") VALUES ('Near_Muslim', 'SQL3', CURRENT_DATE);
*/
-----------------------------------------------
--                  P2P                      --
-----------------------------------------------
CREATE TABLE IF NOT EXISTS P2P (
    ID INTEGER PRIMARY KEY,
    "Check" INTEGER,
    "Checking Peer" VARCHAR,
    State CheckStatus,
    "Time" time,
   FOREIGN KEY ("Check" ) REFERENCES Checks(ID)
);

COPY P2P FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/P2P.csv' DELIMITER ';' CSV HEADER;
/*
insert into P2P values(fnc_next_id('P2P'), 1, 'Luisi', 'Start', '16:00:57');
    insert into P2P values(fnc_next_id('P2P'), 1, 'Luisi', 'Success', '17:00:25');

    insert into P2P values(fnc_next_id('P2P'), 2, 'Luisi', 'Start', '16:18:57');
    insert into P2P values(fnc_next_id('P2P'), 2, 'Luisi', 'Success', '17:00:25');

    insert into P2P values(fnc_next_id('P2P'), 3, 'Near_Muslim', 'Start', '15:00:40');
    insert into P2P values(fnc_next_id('P2P'), 3, 'Near_Muslim', 'Success', '15:26:22');

    insert into P2P values(fnc_next_id('P2P'), 4, 'Pirate', 'Start', '15:00:40');
    insert into P2P values(fnc_next_id('P2P'), 4, 'Pirate', 'Success', '15:26:22');

    insert into P2P values(fnc_next_id('P2P'), 5, 'Gabriel', 'Start', '15:16:17');
    insert into P2P values(fnc_next_id('P2P'), 5, 'Gabriel', 'Success', '16:17:18');

    insert into P2P values(fnc_next_id('P2P'), 6, 'Near_Muslim', 'Start', '18:15:20');
    insert into P2P values(fnc_next_id('P2P'), 6, 'Near_Muslim', 'Success', '19:15:21');

    insert into P2P values(fnc_next_id('P2P'), 7, 'Luisi', 'Start', '15:00:40');
    insert into P2P values(fnc_next_id('P2P'), 7, 'Luisi', 'Success', '15:26:22');

    insert into P2P values(fnc_next_id('P2P'), 8, 'Strangler', 'Start', '19:30:21');
    insert into P2P values(fnc_next_id('P2P'), 8, 'Strangler', 'Success', '20:00:00');

    insert into P2P values(fnc_next_id('P2P'), 9, 'Gabriel', 'Start', '10:19:20');
    insert into P2P values(fnc_next_id('P2P'), 9, 'Gabriel', 'Success', '11:20:21');

    insert into P2P values(fnc_next_id('P2P'), 10, 'Pirate', 'Start', '15:00:40');
    insert into P2P values(fnc_next_id('P2P'), 10, 'Pirate', 'Success', '15:26:22');

    insert into P2P values(fnc_next_id('P2P'), 11, 'Pirate', 'Start', '08:01:21');
    insert into P2P values(fnc_next_id('P2P'), 11, 'Pirate', 'Success', '08:30:02');

    insert into P2P values(fnc_next_id('P2P'), 12, 'Wolf', 'Start', '18:19:20');
    insert into P2P values(fnc_next_id('P2P'), 12, 'Wolf', 'Success', '19:20:21');

    insert into P2P values(fnc_next_id('P2P'), 13, 'Wolf', 'Start', '15:00:40');
    insert into P2P values(fnc_next_id('P2P'), 13, 'Wolf', 'Success', '15:26:22');

    insert into P2P values(fnc_next_id('P2P'), 14, 'Luisi', 'Start', '15:00:40');
    insert into P2P values(fnc_next_id('P2P'), 14, 'Luisi', 'Success', '15:26:22');

    insert into P2P values(fnc_next_id('P2P'), 15, 'Luisi', 'Start', '12:13:14');
    insert into P2P values(fnc_next_id('P2P'), 15, 'Luisi', 'Failure', '13:14:15');
*/



-----------------------------------------------
--                 Verter                    --
-----------------------------------------------

 CREATE TABLE IF NOT EXISTS Verter (
     ID INTEGER PRIMARY KEY,
    "Check" INTEGER,
    State CheckStatus,
    "Time" time,
    FOREIGN KEY ("Check" ) REFERENCES Checks(ID)
 );
COPY Verter FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/verter.csv' DELIMITER ';' CSV HEADER;
/* 
insert into Verter values(fnc_next_id('Verter'), 1, 'Start', '13:14:15');
    insert into Verter values(fnc_next_id('Verter'), 1, 'Success', '13:15:15');

    insert into Verter values(fnc_next_id('Verter'), 2, 'Start', '20:21:22');
    insert into Verter values(fnc_next_id('Verter'), 2, 'Success', '20:22:22');

    insert into Verter values(fnc_next_id('Verter'), 3, 'Start', '13:14:15');
    insert into Verter values(fnc_next_id('Verter'), 3, 'Success', '13:15:15');

    insert into Verter values(fnc_next_id('Verter'), 4, 'Start', '20:21:22');
    insert into Verter values(fnc_next_id('Verter'), 4, 'Success', '20:22:22');

    insert into Verter values(fnc_next_id('Verter'), 5, 'Start', '13:14:15');
    insert into Verter values(fnc_next_id('Verter'), 5, 'Success', '13:15:15');

    insert into Verter values(fnc_next_id('Verter'), 6, 'Start', '20:21:22');
    insert into Verter values(fnc_next_id('Verter'), 6, 'Success', '20:22:22');

    insert into Verter values(fnc_next_id('Verter'), 7, 'Start', '13:14:15');
    insert into Verter values(fnc_next_id('Verter'), 7, 'Success', '13:15:15');

    insert into Verter values(fnc_next_id('Verter'), 8, 'Start', '20:21:22');
    insert into Verter values(fnc_next_id('Verter'), 8, 'Success', '20:22:22');

    insert into Verter values(fnc_next_id('Verter'), 9, 'Start', '21:22:23');
    insert into Verter values(fnc_next_id('Verter'), 9, 'Success', '21:23:23');

    insert into Verter values(fnc_next_id('Verter'), 10, 'Start', '13:14:15');
    insert into Verter values(fnc_next_id('Verter'), 10, 'Success', '13:15:15');

    insert into Verter values(fnc_next_id('Verter'), 11, 'Start', '20:21:22');
    insert into Verter values(fnc_next_id('Verter'), 11, 'Success', '20:22:22');

    insert into Verter values(fnc_next_id('Verter'), 12, 'Start', '20:21:22');
    insert into Verter values(fnc_next_id('Verter'), 12, 'Success', '20:22:22');

    insert into Verter values(fnc_next_id('Verter'), 13, 'Start', '13:14:15');
    insert into Verter values(fnc_next_id('Verter'), 13, 'Success', '13:15:15');

    insert into Verter values(fnc_next_id('Verter'), 14, 'Start', '13:14:15');
    insert into Verter values(fnc_next_id('Verter'), 14, 'Success', '13:15:15');

    insert into Verter values(fnc_next_id('Verter'), 15, 'Start', '20:21:22');
    insert into Verter values(fnc_next_id('Verter'), 15, 'Success', '20:22:22');
*/
-----------------------------------------------
--             TransferredPoints             --
-----------------------------------------------

CREATE TABLE IF NOT EXISTS TransferredPoints(
  ID INTEGER PRIMARY KEY,
  CheckingPeer VARCHAR,
  CheckedPeer VARCHAR,
  PointsAmount INTEGER,
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
  FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname)
);
COPY TransferredPoints FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/transferred_points.csv' DELIMITER ';' CSV HEADER;
/* 
 insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Near_Muslim', 'Luisi', 3);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Strangler', 'Luisi', 1);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Gabriel', 'Near_Muslim', 3);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Gabriel', 'Pirate', 4);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Near_Muslim', 'Gabriel', 1);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Strangler', 'Near_Muslim', 1);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Gabriel', 'Luisi', 1);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Near_Muslim', 'Strangler', 1);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Strangler', 'Gabriel', 3);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Near_Muslim', 'Pirate', 2);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Strangler', 'Wolf', 3);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Gabriel', 'Wolf', 3);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Sprat_eater', 'Luisi', 1);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Sprat_eater', 'Strangler', 4);
    insert into TransferredPoints values(fnc_next_id('TransferredPoints'),'Near_Muslim', 'Sprat_eater', 1);
    */
-----------------------------------------------
--                  Friends                  --
-----------------------------------------------
CREATE TABLE IF NOT EXISTS Friends(
    ID INTEGER PRIMARY KEY,
  Peer1 VARCHAR,
  Peer2 VARCHAR,
    FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
   FOREIGN KEY (Peer2) REFERENCES Peers(Nickname)
);
COPY Friends FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/friends.csv' DELIMITER ';' CSV HEADER;
/* 
    insert into Friends values(fnc_next_id('Friends'), 'Wolf', 'Sprat_eater');
    insert into Friends values(fnc_next_id('Friends'), 'Wolf', 'Luisi');
    insert into Friends values(fnc_next_id('Friends'), 'Wolf', 'Gabriel');
    insert into Friends values(fnc_next_id('Friends'), 'Sprat_eater', 'Near_Muslim');
    insert into Friends values(fnc_next_id('Friends'), 'Sprat_eater', 'Luisi');
    insert into Friends values(fnc_next_id('Friends'), 'Near_Muslim', 'Gabriel');
    insert into Friends values(fnc_next_id('Friends'), 'Near_Muslim', 'Pirate');
    insert into Friends values(fnc_next_id('Friends'), 'Pirate', 'Wolf');
    insert into Friends values(fnc_next_id('Friends'), 'Pirate', 'Strangler');
    insert into Friends values(fnc_next_id('Friends'), 'Strangler', 'Wolf');
    insert into Friends values(fnc_next_id('Friends'), 'Luisi', 'Near_Muslim');
    insert into Friends values(fnc_next_id('Friends'), 'Gabriel', 'Luisi');
    */
-----------------------------------------------
--       Recommendations                    --
-----------------------------------------------

CREATE TABLE IF NOT EXISTS Recommendations(
    ID INTEGER PRIMARY KEY,
  Peer VARCHAR,
  RecommendedPeer VARCHAR,
   FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
   FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname)
);
COPY Recommendations FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/recommendations.csv' DELIMITER ';' CSV HEADER;
/* 
 insert into Recommendations values(fnc_next_id('Recommendations'), 'Wolf', 'Near_Muslim');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Wolf', 'Pirate');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Wolf', 'Strangler');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Sprat_eater', 'Pirate');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Near_Muslim', 'Luisi');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Near_Muslim', 'Gabriel');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Pirate', 'Sprat_eater');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Pirate', 'Gabriel');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Strangler', 'Gabriel');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Strangler', 'Wolf');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Strangler', 'Pirate');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Strangler', 'Luisi');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Gabriel', 'Sprat_eater');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Luisi', 'Sprat_eater');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Luisi', 'Pirate');
    insert into Recommendations values(fnc_next_id('Recommendations'), 'Luisi', 'Gabriel');
   */
-----------------------------------------------
--                  XP                    --
-----------------------------------------------

CREATE TABLE IF NOT EXISTS XP
(
    ID INTEGER PRIMARY KEY,
    "Check" INTEGER,
    XPAmount INTEGER,
    FOREIGN KEY ("Check") REFERENCES  Checks(ID)
);
COPY XP FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/xp.csv' DELIMITER ';' CSV HEADER;
/* 
insert into XP values(fnc_next_id('XP'), 1, 300);
    insert into XP values(fnc_next_id('XP'), 2, 300);
    insert into XP values(fnc_next_id('XP'), 3, 300);
    insert into XP values(fnc_next_id('XP'), 4, 400);
    insert into XP values(fnc_next_id('XP'), 5, 240);
    insert into XP values(fnc_next_id('XP'), 6, 400);
    insert into XP values(fnc_next_id('XP'), 7, 300);
    insert into XP values(fnc_next_id('XP'), 8, 350);
    insert into XP values(fnc_next_id('XP'), 9, 300);
    insert into XP values(fnc_next_id('XP'), 10, 350);
    insert into XP values(fnc_next_id('XP'), 11, 350);
    insert into XP values(fnc_next_id('XP'), 12, 350);
    insert into XP values(fnc_next_id('XP'), 13, 400);
    insert into XP values(fnc_next_id('XP'), 14, 300);
    insert into XP values(fnc_next_id('XP'), 15, 400);
 */   

-----------------------------------------------
--                 TimeTracking                    --
-----------------------------------------------

CREATE TABLE IF NOT EXISTS TimeTracking (
     ID INTEGER PRIMARY KEY,
     Peer VARCHAR,
     "Date" DATE,
     "Time" TIME,
     State INTEGER,
     FOREIGN KEY (Peer) REFERENCES Peers(Nickname)

);

COPY TimeTracking FROM '/Users/bulahgen/SQL2_Info21_v1.0-1/src/dataset_sql/time_tracking.csv' DELIMITER ';' CSV HEADER;
/* insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Wolf', '2022-12-01', '11:24:11', 1);
    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Wolf', '2022-12-01', '23:42:00', 2);

    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Near_Muslim', '2022-12-01', '09:05:54', 1);
    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Near_Muslim', '2022-12-01', '23:42:00', 2);

    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Sprat_eater', '2022-12-05', '13:44:01', 1);
    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Sprat_eater', '2022-12-05', '23:42:00', 2);

    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Pirate', '2022-12-07', '00:00:00', 1);
    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Pirate', '2022-12-07', '23:59:59', 2);

    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Near_Muslim', '2022-12-10', '23:59:59', 1);
    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Near_Muslim', '2022-12-11', '02:42:59', 2);

    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Strangler', '2022-12-11', '05:41:34', 1);
    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Strangler', '2022-12-11', '20:30:47', 2);

    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Strangler', '2022-12-24', '10:14:22', 1);
    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Strangler', '2022-12-24', '12:29:17', 2);

    insert into TimeTracking values(fnc_next_id('TimeTracking'), 'Gabriel', '2022-12-28', '20:30:47', 1);


--CREATE OR REPLACE FUNCTION fnc_next_id(table_name VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    next_id INTEGER;
BEGIN
    EXECUTE 'SELECT COALESCE(MAX(ID), 0) + 1 FROM ' || table_name INTO next_id;
    RETURN next_id;
END;
$$ LANGUAGE plpgsql;
*/
----------------------------------------------------------------------------------------------
--                                      import and export                                   --
----------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE IMPORT1 ( table_name VARCHAR(50),
    filePath VARCHAR(100),
    delimiter VARCHAR(5) DEFAULT ',')
LANGUAGE plpgsql AS $$
BEGIN
     EXECUTE format('COPY %I FROM %L WITH DELIMITER %L CSV HEADER',table_name, filePath,  delimiter);
END $$;

--CALL IMPORT1('prov','/dataset_sql/peers.csv', ';' );
--CREATE TABLE IF NOT EXISTS prov (
 --  Nickname VARCHAR PRIMARY KEY NOT NULL,
 --   Birthday DATE
--);



CREATE OR REPLACE PROCEDURE EXPORT(table_name VARCHAR(50),
    filePath VARCHAR(100),
    delimiter VARCHAR(5) DEFAULT ';')
LANGUAGE plpgsql AS $$
BEGIN
         EXECUTE FORMAT('COPY %I TO %L WITH DELIMITER %L CSV HEADER',table_name, filePath,  delimiter);
END $$;
--CALL EXPORT('tasks','/SQL2_Info21_v1.0-1/src/12.csv', ';' );
