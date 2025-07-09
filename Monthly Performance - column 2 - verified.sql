
DECLARE @result_run_id INT
DECLARE @previous_result_run_id INT


-- Get first latest pk
SELECT @result_run_id = pk
FROM sts_result_run
WHERE fk_sts_result = 7 AND superseded_flag = 'N'
ORDER BY pk DESC
OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

-- Get second latest pk
SELECT @previous_result_run_id = pk
FROM sts_result_run
WHERE fk_sts_result = 7 AND superseded_flag = 'N'
ORDER BY pk DESC
OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;

PRINT 'Result Run ID: ' + CAST(@result_run_id AS VARCHAR)
PRINT 'Previous Result Run ID: ' + CAST(@previous_result_run_id AS VARCHAR)


-- Use CTEs to simplify and isolate values
--;WITH Previous90Days AS (
--    SELECT
--        '90 Days' = SUM(CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END)
--    FROM AQTEST.dbo.v_sts_act_tb_full
--    WHERE pk_sts_result_run = @previous_result_run_id
--),



;WITH Previous90Days AS (
    SELECT
        [90 Days] = SUM(CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END),
        DateLabel = FORMAT(
            DATEFROMPARTS(
                CASE 
                    WHEN [month] >= 7 THEN CAST(LEFT(fk_financial_year, 4) AS INT)
                    ELSE CAST(RIGHT(fk_financial_year, 2) AS INT) + 2000
                END,
                [month],
                1
            ),
            'MMM-yy'
        )
    FROM AQTEST.dbo.v_sts_act_tb_full
    WHERE pk_sts_result_run = @previous_result_run_id
),

Current120Days AS (
    SELECT
        "120 Days Following Month" = SUM(CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END)
    FROM AQTEST.dbo.v_sts_act_tb_full
    WHERE pk_sts_result_run = @result_run_id
)

-- Final select with join and %paid calculation
SELECT 
    p.[90 Days],
    c.[120 Days Following Month],
    [% Paid] = 
        CASE 
            WHEN p.[90 Days] = 0 THEN NULL
            ELSE CAST(ROUND(
                (CAST(p.[90 Days] AS FLOAT) - CAST(c.[120 Days Following Month] AS FLOAT)) 
                / CAST(p.[90 Days] AS FLOAT) * 100, 
                2
            ) AS VARCHAR) + ' %'
        END
FROM Previous90Days p
CROSS JOIN Current120Days c
