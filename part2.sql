----------------------------------------------------------------------------------------------
--                      1) Write a procedure for adding P2P check                           --
----------------------------------------------------------------------------------------------
    CREATE OR REPLACE PROCEDURE add_p2p(
    IN checked_peer VARCHAR,
    IN checking_peer VARCHAR,
    IN Task VARCHAR,
    IN State CheckStatus,
    IN "Time" TIME
) AS $$
DECLARE
    check_id INTEGER;
    last_p2p_check_state checkstatus;
BEGIN
    SELECT p.State
    INTO last_p2p_check_state
    FROM P2P p
    JOIN Checks ch ON p."Check" = ch.ID
    WHERE ch.Peer = checked_peer AND
          p.checkingpeer = checking_peer AND
          ch.Task = add_p2p.Task
    ORDER BY p.ID DESC
    LIMIT 1;

    IF State = 'Start' THEN
        IF NOT EXISTS (SELECT 1 FROM Tasks WHERE Title = Task) THEN
            RETURN;
        END IF;
        INSERT INTO Checks
        VALUES (COALESCE((SELECT MAX(ID) + 1 FROM Checks), 1), checked_peer, Task, CURRENT_DATE)
        RETURNING ID INTO check_id;

        INSERT INTO P2P
        VALUES (COALESCE((SELECT MAX(ID) + 1 FROM P2P), 1), check_id, checking_peer, State, "Time");

    ELSIF State IN ('Success', 'Failure') THEN
        IF last_p2p_check_state = 'Start' AND last_p2p_check_state IS NOT NULL THEN
            INSERT INTO P2P
            VALUES (
                COALESCE((SELECT MAX(ID) + 1 FROM P2P), 1),
                (SELECT MAX("Check")
                 FROM P2P
                 JOIN Checks ON P2P."Check" = Checks.ID
                 WHERE P2P.checkingpeer = checking_peer AND
                       Checks.Peer = checked_peer AND
                       Checks.Task = add_p2p.Task
                 ),
                checking_peer,
                State,
                "Time"
            );
        ELSE
            RAISE EXCEPTION 'Нет начатой проверки относящейся к конкретному заданию, пиру и проверяющему.';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;


--CALL add_p2p('jlbpsacywv', 'iosfiypdje', 'SQL3', 'Success', '22:32:45')

----------------------------------------------------------------------------------------------
--                 2) Write a procedure for adding checking by Verter                       --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE add_verter(IN nick_checkedpeer varchar, IN task_name text,
                            IN verter_status checkstatus, IN check_time time) AS $$
    BEGIN
        IF (verter_status = 'Start') THEN
                IF ((SELECT MAX(p2p."Time") FROM p2p
                    JOIN checks ON p2p."Check" = checks.id
                    WHERE checks.peer = nick_checkedpeer AND checks.task = task_name
                        AND p2p.state = 'Success') IS NOT NULL ) THEN

                    INSERT INTO verter
                    VALUES ((SELECT MAX(id) FROM verter) + 1,
                            (SELECT DISTINCT checks.id FROM p2p
                             JOIN checks ON p2p."Check" = checks.id
                             WHERE checks.peer = nick_checkedpeer AND p2p.state = 'Success'
                                AND checks.task = task_name),
                            verter_status, check_time);
            ELSE
                RAISE EXCEPTION 'Добавление записи невозможно.'
                    'P2P-проверка для задания не завершена или имеет статус Failure';
            END IF;
        ELSE
            INSERT INTO verter
            VALUES ((SELECT MAX(id) FROM verter) + 1,
                    (SELECT "Check" FROM verter
                     GROUP BY "Check" HAVING COUNT(*) % 2 = 1), verter_status, check_time);
        END IF;
    END;
$$ LANGUAGE plpgsql;

--CALL add_verter('jlbpsacywv', 'SQL2', 'Start', '23:40:00');


----------------------------------------------------------------------------------------------
--       3) Write a trigger: after adding a record with the "start" status to the P2P
--            table, change the corresponding record in the TransferredPoints table         --
----------------------------------------------------------------------------------------------
/* DROP TRIGGER afterInsertP2P ON P2P;

DROP FUNCTION updateTransferredPoints();

CREATE OR REPLACE FUNCTION updateTransferredPoints()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE TransferredPoints AS TP
    SET PointsAmount = PointsAmount + 1
    WHERE NEW."Checking Peer" = TP.CheckingPeer AND
          (
            (SELECT Peer FROM Checks WHERE NEW."Check" = Checks.ID) IS NOT NULL AND
            (SELECT Peer FROM Checks WHERE NEW."Check" = Checks.ID) = TP.CheckedPeer
          );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER afterInsertP2P
AFTER INSERT ON P2P
FOR EACH ROW
    WHEN (NEW.state = 'Start')
EXECUTE FUNCTION updateTransferredPoints();
select * from transferredpoints

 */

----------------------------------------------------------------------------------------------
--                4) Write a trigger: before adding a record to the XP table,
--                                  check if it is correct                                  --
----------------------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_xp_insert_audit1 ON xp;

CREATE OR REPLACE FUNCTION fnc_trg_xp_insert_audit1()
    RETURNS trigger AS $$
DECLARE
    max_xp_task INTEGER;
    p2p_state TEXT;
    verter_state TEXT;
    success_check BOOL;
BEGIN

    SELECT max_xp INTO max_xp_task
    FROM Tasks
    WHERE title = (SELECT Task FROM Checks WHERE Checks.id = NEW."Check");

    SELECT state INTO p2p_state
    FROM P2P
    WHERE "Check" = NEW."Check"
    ORDER BY id DESC
    LIMIT 1;

    SELECT state INTO verter_state
    FROM Verter
    WHERE "Check" = NEW."Check"
    ORDER BY id DESC
    LIMIT 1;

    success_check := p2p_state = 'Success' AND (verter_state IS NULL OR verter_state = 'Success');
    IF NOT success_check THEN
        RAISE EXCEPTION 'Данная проверка неуспешна :(';
    ELSIF NEW.xpamount > max_xp_task THEN
        RAISE EXCEPTION 'Количество начисляемого опыта больше максимального допустимого :(';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_xp_insert_audit1
BEFORE INSERT ON xp
FOR EACH ROW
EXECUTE FUNCTION fnc_trg_xp_insert_audit1();


INSERT INTO xp VALUES ((SELECT COALESCE(MAX(id)+1, 1) FROM xp), 2, 158);


SELECT * FROM xp WHERE XPAmount = 158;
