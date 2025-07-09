DECLARE @result_run_id INT;
DECLARE @previous_result_run_id INT;

-- Get the most recent and previous result_run_id
SELECT TOP 2
    pk,
    rn = ROW_NUMBER() OVER (ORDER BY pk DESC)
INTO #temp_runs
FROM sts_result_run
WHERE fk_sts_result = 7 AND superseded_flag = 'N';

-- Assign to variables
SELECT @result_run_id = pk FROM #temp_runs WHERE rn = 1;
SELECT @previous_result_run_id = pk FROM #temp_runs WHERE rn = 2;

DROP TABLE #temp_runs;

-- CTE for both result runs
;WITH MonthlySums AS (
    SELECT  
        st.pk_sts_result_run,
        fk_financial_year,
        [month],
        MonthLabel = FORMAT(
            DATEFROMPARTS(
                CASE 
                    WHEN [month] >= 7 THEN CAST(LEFT(fk_financial_year, 4) AS INT)
                    ELSE CAST(RIGHT(fk_financial_year, 2) AS INT) + 2000
                END,
                [month],
                1
            ),
            'MMM-yy'
        ),
        [90 Days] = SUM(CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END), 
        [120 Days] = SUM(CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END), 
        [120+ Days] = SUM(
            CASE 
                WHEN ISNULL(amt_120days_plus, 0) + ISNULL(amt_121to365days, 0) + ISNULL(amt_365days_plus, 0) < 0 
                    THEN 0 
                    ELSE ISNULL(amt_120days_plus, 0) + ISNULL(amt_121to365days, 0) + ISNULL(amt_365days_plus, 0)
            END
        )
    FROM AQTEST.dbo.v_sts_act_tb_full st
    WHERE st.pk_sts_result_run IN (@result_run_id, @previous_result_run_id)
    GROUP BY st.pk_sts_result_run, fk_financial_year, [month]
),
WithTotals AS (
    SELECT *,
        TotalAmount = [90 Days] + [120 Days] + [120+ Days],
        DateSort = DATEFROMPARTS(
            CASE 
                WHEN [month] >= 7 THEN CAST(LEFT(fk_financial_year, 4) AS INT)
                ELSE CAST(RIGHT(fk_financial_year, 2) AS INT) + 2000
            END,
            [month],
            1
        )
    FROM MonthlySums
),
FinalOutput AS (
    SELECT 
        MonthLabel,
        [90 Days],
        [120 Days],
        [120+ Days],
        TotalAmount,
        DateSort,  -- INCLUDE DateSort here
        MonthlyChange = TotalAmount - LAG(TotalAmount) OVER (ORDER BY DateSort)
    FROM WithTotals
)

-- Final output (DateSort removed from display, just used for ordering)
SELECT 
    MonthLabel,
    [90 Days],
    [120 Days],
    [120+ Days],
    TotalAmount,
    MonthlyChange
FROM FinalOutput
ORDER BY DateSort DESC;
