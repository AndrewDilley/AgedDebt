--prompt

--please take this query 

--DECLARE @result_run_id INT

--SET @result_run_id = (
--    SELECT MAX(pk)
--    FROM sts_result_run
--    WHERE fk_sts_result = 7 AND superseded_flag = 'N'
--)

--SELECT  
--    '90 Days'  = SUM(CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END), 
--    '120 Days' = SUM(CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END), 
--    '120+ Days' = SUM(
--                      CASE 
--                          WHEN ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0) < 0 
--                          THEN 0 
--                          ELSE ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0) 
--                      END
--                  )
--FROM AQTEST.dbo.v_sts_act_tb_full st 
--WHERE st.pk_sts_result_run = @result_run_id


--and make the following changes

--1) instead of SELECT MAX(pk), use (MAX(pk) - 1) to give @result_run_id
--2) instead of SELECT MAX(pk), use (MAX(pk) - 2) to give @previous_result_run_id
--3) drop the '120 Days' and '120+ Days' coulumns
--4) keep the '90 Days' and keep this as being generated with st.pk_sts_result_run = @previous_result_run_id
--5) make a new calcluated field called "120 Days Following Month" which has the formula '120 Days' = SUM(CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END), and is generated with st.pk_sts_result_run = @result_run_id
--6) make a new calculated field called "%paid" which equals (('90 Days' - "120 Days Following Month") / '90 Days') expressed as a percentage



DECLARE @result_run_id INT
DECLARE @previous_result_run_id INT


-- Get second latest pk
SELECT @result_run_id = pk
FROM sts_result_run
WHERE fk_sts_result = 7 AND superseded_flag = 'N'
ORDER BY pk DESC
OFFSET 1 ROW FETCH NEXT 1 ROWS ONLY;

-- Get third latest pk
SELECT @previous_result_run_id = pk
FROM sts_result_run
WHERE fk_sts_result = 7 AND superseded_flag = 'N'
ORDER BY pk DESC
OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY;

PRINT 'Result Run ID: ' + CAST(@result_run_id AS VARCHAR)
PRINT 'Previous Result Run ID: ' + CAST(@previous_result_run_id AS VARCHAR)


-- Use CTEs to simplify and isolate values
;WITH Previous90Days AS (
    SELECT
        '90 Days' = SUM(CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END)
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
