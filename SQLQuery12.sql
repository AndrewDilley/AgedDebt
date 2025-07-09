-- CTE for all valid result runs back to April 2010
;WITH MonthlySums AS (
    SELECT  
        st.pk_sts_result_run,
        st.fk_financial_year,
        st.[month],
        MonthLabel = FORMAT(
            DATEFROMPARTS(
                CASE 
                    WHEN st.[month] >= 7 THEN CAST(LEFT(st.fk_financial_year, 4) AS INT)
                    ELSE CAST(RIGHT(st.fk_financial_year, 2) AS INT) + 2000
                END,
                st.[month],
                1
            ),
            'MMM-yy'
        ),
        [90 Days] = SUM(CASE WHEN st.amt_61to90days < 0 THEN 0 ELSE st.amt_61to90days END), 
        [120 Days] = SUM(CASE WHEN st.amt_91to120days < 0 THEN 0 ELSE st.amt_91to120days END), 
        [120+ Days] = SUM(
            CASE 
                WHEN ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0) < 0 
                    THEN 0 
                    ELSE ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0)
            END
        )
    FROM AQTEST.dbo.v_sts_act_tb_full st
    INNER JOIN sts_result_run rr
        ON st.pk_sts_result_run = rr.pk
    WHERE rr.fk_sts_result = 7
      AND rr.superseded_flag = 'N'
    GROUP BY st.pk_sts_result_run, st.fk_financial_year, st.[month]
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
    WHERE DATEFROMPARTS(
              CASE 
                  WHEN [month] >= 7 THEN CAST(LEFT(fk_financial_year, 4) AS INT)
                  ELSE CAST(RIGHT(fk_financial_year, 2) AS INT) + 2000
              END,
              [month],
              1
          ) >= '2010-04-01'
),
FinalOutput AS (
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
FROM FinalOutput
ORDER BY DateSort DESC;
