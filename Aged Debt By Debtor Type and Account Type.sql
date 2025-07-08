DECLARE @result_run_id INT

SET @result_run_id = (Select MAX(pk) from sts_result_run where fk_sts_result = 7 and superseded_flag = 'N')

Select  
'Year'               = st.fk_financial_year, 
'Month'              = st.month,
'Debtor Type'        = st.acct_deb_type_desc, 
'Account Type'       = st.account_type_desc, 
'90 Days'            = SUM( CASE WHEN amt_61to90days < 0 THEN 0 ELSE amt_61to90days END ), 
'120 Days'           = SUM( CASE WHEN amt_91to120days < 0 THEN 0 ELSE amt_91to120days END ), 
'120+ Days'          = SUM( CASE WHEN ISNULL(st.amt_120days_plus,0 ) +  ISNULL(st.amt_121to365days,0 ) + ISNULL(st.amt_365days_plus,0 ) < 0 THEN 0 
                                  ELSE ISNULL(st.amt_120days_plus,0 ) +  ISNULL(st.amt_121to365days,0 ) + ISNULL(st.amt_365days_plus,0  ) END )
From AQTEST.dbo.v_sts_act_tb_full st 
Where st.pk_sts_result_run = @result_run_id 
Group By st.fk_financial_year, st.month, st.acct_deb_type_desc, st.account_type_desc 
Order By acct_deb_type_desc, account_type_desc