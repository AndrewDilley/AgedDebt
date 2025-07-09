DECLARE @result_run_id INT
DECLARE @previous_result_run_id INT;

-- Get latest pk (1st most recent)
SELECT @result_run_id = pk
FROM sts_result_run
WHERE fk_sts_result = 7 AND superseded_flag = 'N'
ORDER BY pk DESC
OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

-- Get second latest pk (2nd most recent)
SELECT @previous_result_run_id = pk
FROM sts_result_run
WHERE fk_sts_result = 7 AND superseded_flag = 'N'
ORDER BY pk DESC
OFFSET 1 ROW FETCH NEXT 1 ROWS ONLY;


-- CTE to rank date groups for previous run
;WITH PreviousData AS (
    SELECT
        fk_financial_year,
        [month],
        [90 Plus Days] = SUM(CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END) +
		     SUM(
                      CASE 
                          WHEN ISNULL(amt_120days_plus, 0) + ISNULL(amt_121to365days, 0) + ISNULL(amt_365days_plus, 0) < 0 
                          THEN 0 
                          ELSE ISNULL(amt_120days_plus, 0) + ISNULL(amt_121to365days, 0) + ISNULL(amt_365days_plus, 0) 
                      END
                  )
,
        RowNum = ROW_NUMBER() OVER (
            ORDER BY 
                -- Convert to real calendar date for ordering
                DATEFROMPARTS(
                    CASE 
                        WHEN [month] >= 7 THEN CAST(LEFT(fk_financial_year, 4) AS INT)
                        ELSE CAST(RIGHT(fk_financial_year, 2) AS INT) + 2000
                    END,
                    [month],
                    1
                ) DESC
        )
    FROM AQTEST.dbo.v_sts_act_tb_full
    WHERE pk_sts_result_run = @previous_result_run_id
    GROUP BY fk_financial_year, [month]
),
Previous90PlusDays AS (
    SELECT 
        [90 Plus Days],
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
    FROM PreviousData
    WHERE RowNum = 1
),
Current120PlusDays AS (
    SELECT

		[120 Plus Days Following Month] = SUM(
                      CASE 
                          WHEN ISNULL(amt_120days_plus, 0) + ISNULL(amt_121to365days, 0) + ISNULL(amt_365days_plus, 0) < 0 
                          THEN 0 
                          ELSE ISNULL(amt_120days_plus, 0) + ISNULL(amt_121to365days, 0) + ISNULL(amt_365days_plus, 0) 
                      END
                  )

    FROM AQTEST.dbo.v_sts_act_tb_full
    WHERE pk_sts_result_run = @result_run_id
)

-- Final result
SELECT 
    p.DateLabel,
    p.[90 Plus Days],
    c.[120 Plus Days Following Month],
    [% Paid] = 
        CASE 
            WHEN p.[90 Plus Days] = 0 THEN NULL
            ELSE CAST(ROUND(
                (CAST(p.[90 Plus Days] AS FLOAT) - CAST(c.[120 Plus Days Following Month] AS FLOAT)) 
                / CAST(p.[90 Plus Days] AS FLOAT) * 100, 
                2
            ) AS VARCHAR) + ' %'
        END
FROM Previous90PlusDays p
CROSS JOIN Current120PlusDays c;
