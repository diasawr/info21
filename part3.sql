
----------------------------------------------------------------------------------------------
--          1)Write a function that returns the TransferredPoints table in a more
--                                  human-readable form                                     --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION returningTransferredPoints()
RETURNS TABLE(Peer1 VARCHAR, Peer2 VARCHAR, "PointsAmount" BIGINT) AS $$
BEGIN
	RETURN QUERY
	SELECT
		LEAST(CheckingPeer, CheckedPeer) AS Peer1,
		GREATEST(CheckingPeer, CheckedPeer) AS Peer2,
		SUM(CASE WHEN CheckingPeer > CheckedPeer THEN PointsAmount ELSE -PointsAmount END) AS "PointsAmount"
	FROM TransferredPoints
	GROUP BY Peer1, Peer2;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM returningTransferredPoints();

----------------------------------------------------------------------------------------------
--           2) Write a function that returns a table of the following form: user 
--              name, name of the checked task, number of XP received                       --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION xp_peer()
RETURNS TABLE(Peer VARCHAR, Task VARCHAR, XP INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT C.Peer, C.Task, X.XPAmount
    FROM Checks AS C
    JOIN XP AS X ON C.ID = X."Check"
    JOIN P2P AS P ON C.ID = P."Check"
    WHERE P.State = 'Success';
END;
$$;

----------------------------------------------------------------------------------------------
--              3) Write a function that finds the peers who have not left 
--                                 campus for the whole day                                 --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION PeerCampusAllDay(date_to_check DATE)
RETURNS TABLE(Peer VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        tt.Peer
    FROM
        TimeTracking tt
    WHERE
        tt."Date" = date_to_check
        AND NOT EXISTS (
            SELECT 1
            FROM TimeTracking tt2
            WHERE
                tt2.Peer = tt.Peer
                AND tt2."Date" = date_to_check
                AND tt2.State = 2
        );
END;
$$;


SELECT * FROM PeerCampusAllDay('2021-02-28');


----------------------------------------------------------------------------------------------
--              4) Calculate the change in the number of peer points of 
--                      each peer using the TransferredPoints table                         --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CalculatePointsChange()
RETURNS TABLE(Peer VARCHAR, PointsChange INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    WITH changes_prp AS (
        SELECT
            checkingpeer AS Peer,
            SUM(pointsamount) AS plus_count
        FROM TransferredPoints
        GROUP BY checkingpeer
        ORDER BY 1
    )
    SELECT
        checked.Peer,
        (COALESCE(plus_count, 0) - COALESCE(minus_count, 0)) AS PointsChange
    FROM
        changes_prp
    LEFT JOIN (
        SELECT  checkedpeer AS Peer, SUM(pointsamount) AS minus_count
        FROM TransferredPoints
        GROUP BY checkedpeer
    ) AS checked ON changes_prp.Peer = checked.Peer;
END;
$$;

-- Пример использования функции
SELECT * FROM CalculatePointsChange();

----------------------------------------------------------------------------------------------
--      5) Calculate the change in the number of peer points of each peer using the
--                      table returned by the first function from Part 3                    --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION changeNumberPeerPoints()
RETURNS TABLE(Peer VARCHAR, PointsChange NUMERIC) AS $$
BEGIN
	RETURN QUERY
	SELECT subquery.Peer, SUM(subquery.PointsChange) AS PointsChange
	FROM (
		SELECT Peer1 AS Peer, "PointsAmount" AS PointsChange
		FROM returningTransferredPoints()
		UNION ALL
		SELECT Peer2 AS Peer, -"PointsAmount" AS PointsChange
		FROM returningTransferredPoints()
	) AS subquery
	GROUP BY subquery.Peer;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM changeNumberPeerPoints();

----------------------------------------------------------------------------------------------
--              6) Find the most frequently checked task for each day                       --
----------------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS mostCheckedTask();

CREATE OR REPLACE FUNCTION mostCheckedTask()
RETURNS TABLE("Day" VARCHAR, "Task" VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT TO_CHAR("Date", 'DD.MM.YYYY')::VARCHAR AS "Day", Task AS "Task"
    FROM (
        SELECT "Date", Task,
               ROW_NUMBER() OVER (PARTITION BY "Date" ORDER BY COUNT(*) DESC) AS number
        FROM Checks
        GROUP BY "Date", Task
    ) AS orderly
    WHERE number = 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM mostCheckedTask();


----------------------------------------------------------------------------------------------
--              7) Find all peers who have completed the whole given block 
--                   of tasks and the completion date of the last task                      --
----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION find_completed_block_peers(block_name VARCHAR)
    RETURNS TABLE(Peer VARCHAR, Day DATE) AS $$
BEGIN
    RETURN QUERY
    WITH block_tasks AS (
        SELECT DISTINCT ON (Checks.Peer) Checks.Peer, "Date"
        FROM Checks
        WHERE Task LIKE '%' || block_name || '%'
        ORDER BY Checks.Peer, "Date" DESC
    )
    SELECT bt.Peer, MAX(bt."Date") AS Day
    FROM block_tasks bt
    GROUP BY bt.Peer
    ORDER BY Day DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_completed_block_peers('CPP');

----------------------------------------------------------------------------------------------
--           8) Determine which peer each student should go to for a check.                 --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION inspectionRecommendation()
RETURNS TABLE(Peer VARCHAR, RecommendedPeer VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT result_table.Peer, result_table.RecommendedPeer
    FROM (
        SELECT prc.Peer, prc.RecommendedPeer,
            ROW_NUMBER() OVER (PARTITION BY prc.Peer ORDER BY COUNT(*) DESC) AS rank
        FROM (
            SELECT frc.RecommendedPeer, COUNT(frc.RecommendedPeer) AS total_recoms, fr.Peer1 AS Peer
            FROM (
                SELECT r.Peer, r.RecommendedPeer, COUNT(r.RecommendedPeer) AS recoms
                FROM Recommendations r
                GROUP BY r.Peer, r.RecommendedPeer
            ) frc
            LEFT JOIN Friends fr ON frc.Peer = fr.Peer2
            WHERE fr.Peer1 != frc.RecommendedPeer
            GROUP BY frc.RecommendedPeer, frc.Peer, fr.Peer1
        ) prc
        WHERE prc.total_recoms = (SELECT MAX(total_recoms) FROM (
                SELECT frc.RecommendedPeer, COUNT(frc.RecommendedPeer) AS total_recoms, fr.Peer1 AS Peer
                FROM (
                    SELECT r.Peer, r.RecommendedPeer, COUNT(r.RecommendedPeer) AS recoms
                    FROM Recommendations r
                    GROUP BY r.Peer, r.RecommendedPeer
                ) frc
                LEFT JOIN Friends fr ON frc.Peer = fr.Peer2
                WHERE fr.Peer1 != frc.RecommendedPeer
                GROUP BY frc.RecommendedPeer, frc.Peer, fr.Peer1
            ) temp
        )
        AND prc.Peer != prc.RecommendedPeer
        GROUP BY prc.Peer, prc.RecommendedPeer, prc.total_recoms
        ORDER BY prc.Peer ASC
    ) result_table
    WHERE result_table.rank = 1;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM inspectionRecommendation();
----------------------------------------------------------------------------------------------
--                       9) Determine the percentage of peers who                           --
----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION blocks_percentage(pblock1 VARCHAR, pblock2 VARCHAR)
RETURNS TABLE (StartedBlock1 BIGINT, StartedBlock2 BIGINT, StartedBothBlocks BIGINT, DidntStartAnyBlocks BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        100 * COUNT(DISTINCT CASE WHEN Task LIKE '%' || pblock1 || '%' THEN Peer END) / COUNT(DISTINCT Peers.Nickname) AS StartedBlock1,
        100 * COUNT(DISTINCT CASE WHEN Task LIKE '%' || pblock2 || '%' THEN Peer END) / COUNT(DISTINCT Peers.Nickname) AS StartedBlock2,
        100 * COUNT(DISTINCT CASE WHEN Task LIKE '%' || pblock1 || '%' AND Task LIKE '%' || pblock2 || '%' THEN Peer END) / COUNT(DISTINCT Peers.Nickname) AS StartedBothBlocks,
        100 * COUNT(DISTINCT Peers.Nickname) FILTER (WHERE Peers.Nickname NOT IN (SELECT DISTINCT Peer FROM Checks WHERE Task LIKE '%' || pblock1 || '%') AND Peers.Nickname NOT IN (SELECT DISTINCT Peer FROM Checks WHERE Task LIKE '%' || pblock2 || '%')) / COUNT(DISTINCT Peers.Nickname) AS DidntStartAnyBlocks
    FROM Peers
    LEFT JOIN Checks ON Checks.Peer = Peers.Nickname;
END;
$$ LANGUAGE plpgsql;

--DROP FUNCTION IF EXISTS blocks_percentage(character varying, character varying);

SELECT * FROM blocks_percentage('D', 'C');
----------------------------------------------------------------------------------------------
--             10) Determine the percentage of peers who have ever successfully
--                             passed a check on their birthday                             --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION birthday_submissions()
RETURNS TABLE (SuccessfulChecks BIGINT, UnsuccessfulChecks BIGINT)
AS $$
DECLARE
    total_passed BIGINT;
    total_missed BIGINT;
BEGIN
    WITH peer_checks AS (
        SELECT pr.Nickname,
               COUNT(DISTINCT ch.ID) AS amount,
               CASE
                   WHEN (Verter.State = 'Success' OR Verter.State IS NULL) AND P2P.State = 'Success' THEN 1
                   ELSE 0
               END AS passed_check,
               CASE
                   WHEN (Verter.State = 'Failure' OR Verter.State IS NULL) AND P2P.State = 'Failure' THEN 1
                   ELSE 0
               END AS missed_check
        FROM Peers AS pr
        INNER JOIN Checks AS ch ON ch.Peer = pr.Nickname
        LEFT JOIN Verter ON Verter."Check" = ch.ID
        LEFT JOIN P2P ON P2P."Check" = ch.ID
        WHERE (EXTRACT(DAY FROM pr.Birthday) = EXTRACT(DAY FROM ch."Date"))
          AND (EXTRACT(MONTH FROM pr.Birthday) = EXTRACT(MONTH FROM ch."Date"))
        GROUP BY pr.Nickname
    )

    SELECT
        COALESCE(SUM(passed_check), 0) AS SuccessfulChecks,
        COALESCE(SUM(missed_check), 0) AS UnsuccessfulChecks
    INTO total_passed, total_missed
    FROM peer_checks;

    RETURN QUERY SELECT
        (COALESCE(total_passed, 0) / NULLIF(total_passed + total_missed, 0) * 100)::BIGINT AS Peer,
        (COALESCE(total_missed, 0) / NULLIF(total_passed + total_missed, 0) * 100)::BIGINT AS RecommendedPeer;
END;
$$ LANGUAGE plpgsql;



SELECT * FROM birthday_submitions();
----------------------------------------------------------------------------------------------
--    11) Determine all peers who did the given tasks 1 and 2, but did not do task 3        --
----------------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS blocks_123(character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION blocks_123(
    task1_name VARCHAR,
    task2_name VARCHAR,
    task3_name VARCHAR
)
RETURNS TABLE (
    Nickname VARCHAR
)
AS $$
BEGIN
    RETURN QUERY
    SELECT pr.Nickname
    FROM Peers pr
    WHERE
        EXISTS (
            SELECT 1
            FROM Checks ch
             JOIN Verter V ON ch.ID = V."Check"
            WHERE ch.Peer = pr.Nickname AND ch.Task = task1_name AND V.State = 'Success'
        )
        AND EXISTS (
            SELECT 1
            FROM Checks ch JOIN Verter V ON ch.ID = V."Check"
            WHERE ch.Peer = pr.Nickname AND ch.Task = task2_name AND V.State = 'Success'
        )
        AND NOT EXISTS (
            SELECT 1
            FROM Checks ch JOIN Verter V ON ch.ID = V."Check"
            WHERE ch.Peer = pr.Nickname AND ch.Task = task3_name AND V.State = 'Success'
        );
END;
$$ LANGUAGE plpgsql;


SELECT * FROM find_peers_completed_tasks('C1', 'C2', 'C6');

----------------------------------------------------------------------------------------------
--               12) Using recursive common table expression, output the number of
--                                  preceding tasks for each task                           --
----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_task_hierarchy()
RETURNS TABLE (
    Task VARCHAR,
    PrevCount INT
)
AS $$
DECLARE
BEGIN
    RETURN QUERY
    WITH RECURSIVE TaskHierarchy AS (
        SELECT
            t1.Title AS Task,
            0 AS PrevCount
        FROM Tasks t1
        WHERE t1.parent_task IS NULL
        UNION ALL
        SELECT
            t2.Title AS Task,
            th.PrevCount + 1 AS PrevCount
        FROM TaskHierarchy th
        JOIN Tasks t2 ON th.Task = t2.parent_task
    )
    SELECT
        th.Task,
        th.PrevCount
    FROM TaskHierarchy th
    ORDER BY th.PrevCount DESC, th.Task;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_task_hierarchy();



select * from tasks

----------------------------------------------------------------------------------------------
--               13) Find "lucky" days for checks. A day is considered "lucky"
--                      if it has at least N consecutive successful checks                  --
----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION lucky_day(IN N INT)
RETURNS TABLE ("Date" DATE)
AS $$
BEGIN
    RETURN QUERY
    WITH che AS (
        SELECT *
        FROM Checks
        JOIN P2P P ON Checks.ID = P."Check"
        LEFT JOIN Verter V ON Checks.ID = V."Check"
        JOIN Tasks ON Checks.task = Tasks.title
        JOIN XP ON Checks.id = XP."Check"
        WHERE P.state = 'Success' AND (V.state = 'Success' OR V.state IS NULL)
    )
    SELECT che."Date"
    FROM che
    WHERE che.xpamount >= che.max_xp * 0.8
    GROUP BY che."Date"
    HAVING COUNT(che."Date") >= N;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM lucky_day(3);



----------------------------------------------------------------------------------------------
--                    14) Find the peer with the highest amount of XP                       --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_max_xp_peer()
RETURNS TABLE (nickname VARCHAR, max_xp_amount INT)
AS $$
BEGIN
    RETURN QUERY
    SELECT peers.nickname, MAX(x.xpamount) AS max_xp_amount
    FROM peers
    JOIN Checks C ON peers.Nickname = C.Peer
    JOIN XP x ON C.ID = x."Check"
    GROUP BY peers.nickname
    ORDER BY max_xp_amount DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_max_xp_peer();

----------------------------------------------------------------------------------------------
--                  15) Determine the peers that came before the given time at
--                              least N times during the whole time                         --
----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION find_active_peers(find_time TIME, min_occurrences INT)
RETURNS TABLE (ActivePeer VARCHAR)
AS $$
BEGIN
    RETURN QUERY
    SELECT Peer
    FROM TimeTracking
    WHERE "Time" < find_time
    GROUP BY Peer
    HAVING COUNT(*) >= min_occurrences;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM coming_peers(TIME '19:08:52', 1);
----------------------------------------------------------------------------------------------
--               16) Determine the peers who left the campus more than M times
--                                       during the last N days                             --
----------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_peers_by_visits(N DATE, M INT)
RETURNS TABLE (Peer VARCHAR)
AS $$
BEGIN
	RETURN QUERY
    SELECT t.peer
    FROM pEERs AS p
        INNER JOIN TIMEtracking AS t
            ON (t.peer = p.nickname)
    WHERE (sTATe = '2') AND ("Date" < N)
    GROUP BY t.peer
    HAVING COUNT(*) > M;
END;
$$ LANGUAGE PLPGSQL;


SELECT * FROM get_peers_by_visits('2021-07-27', 2);
----------------------------------------------------------------------------------------------
--               17) Determine for each month the percentage of early entries               --
----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION count_enter()
RETURNS TABLE(Month varchar, EarlyEntries int) AS $$
DECLARE    
    cur_month varchar;
    EarlyEntries int;
BEGIN    
    FOR cur_month, EarlyEntries IN (
        WITH TrackedTime AS (
            SELECT peer, to_char("Date", 'Month') AS month, "Time", state
            FROM timetracking
        ), PeerBirthdays AS (
            SELECT nickname, to_char(birthday, 'Month') AS bm
            FROM peers
        ), total AS (
            SELECT DISTINCT TrackedTime.month, COUNT(peer) AS total_c
            FROM TrackedTime
            JOIN PeerBirthdays ON peer = nickname
            WHERE TrackedTime.month = bm AND state = 1
            GROUP BY TrackedTime.month
        ), earlyent AS (
            SELECT DISTINCT TrackedTime.month, COUNT(peer) AS early_c
            FROM TrackedTime
            JOIN PeerBirthdays ON peer = nickname
            WHERE TrackedTime.month = bm AND state = 1 AND "Time" < '12:00'
            GROUP BY TrackedTime.month
        )
        SELECT total.month::varchar, (earlyent.early_c * 100 / total.total_c)::int
        FROM total
        JOIN earlyent ON total.month = earlyent.month
    )
    LOOP
        RETURN NEXT;
    END LOOP;
END
$$ LANGUAGE plpgsql;