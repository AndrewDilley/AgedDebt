DECLARE @result_run_id INT

SET @result_run_id = (
    SELECT MAX(pk)
    FROM sts_result_run
    WHERE fk_sts_result = 7 AND superseded_flag = 'N'
)

SELECT  
    'Year'               = st.fk_financial_year, 
    'Month'              = st.month,
    'Debt Stream'        = st.act_debt_stream_desc,
     

    '90 Days'            = SUM(CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END), 
    '120 Days'           = SUM(CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END), 
    '120+ Days'          = SUM(
                              CASE 
                                  WHEN ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0) < 0 
                                  THEN 0 
                                  ELSE ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0) 
                              END
                          ),

    'Total Debt'         = SUM(
                              CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END +
                              CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END +
                              CASE 
                                  WHEN ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0) < 0 
                                  THEN 0 
                                  ELSE ISNULL(st.amt_120days_plus, 0) + ISNULL(st.amt_121to365days, 0) + ISNULL(st.amt_365days_plus, 0) 
                              END
                          )
FROM AQTEST.dbo.v_sts_act_tb_full st 
WHERE st.pk_sts_result_run = @result_run_id 
GROUP BY st.fk_financial_year, st.month, st.act_debt_stream_desc
ORDER BY st.act_debt_stream_desc
