DECLARE @result_run_id INT;
SET @result_run_id = (
    SELECT MAX(pk)
    FROM sts_result_run
    WHERE fk_sts_result = 7 AND superseded_flag = 'N'
);


SELECT DISTINCT fk_financial_year, [month]
FROM AQTEST.dbo.v_sts_act_tb_full
WHERE pk_sts_result_run = @result_run_id
ORDER BY fk_financial_year, [month];
