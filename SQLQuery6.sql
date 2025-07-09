DECLARE @result_run_id INT;

-- Get the latest result run ID
SET @result_run_id = (
    SELECT MAX(pk)
    FROM sts_result_run
    WHERE fk_sts_result = 7 AND superseded_flag = 'N'
);

-- CTE to calculate base values per month
;WITH MonthlySums AS (
    SELECT  
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
    FROM AQTEST.dbo.v_sts_act_tb_full
    WHERE pk_sts_result_run = @result_run_id
    GROUP BY fk_financial_year, [month]
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
WithChange AS (
    SELECT 
        MonthLabel,
        [90 Days],
        [120 Days],
        [120+ Days],
        TotalAmount,
        DateSort,
        MonthlyChange = TotalAmount - LAG(TotalAmount) OVER (ORDER BY DateSort)
    FROM WithTotals
)

-- Final result
SELECT 
    MonthLabel,
    [90 Days],
    [120 Days],
    [120+ Days],
    TotalAmount,
    MonthlyChange
FROM WithChange
ORDER BY DateSort DESC;  -- Most recent month first
