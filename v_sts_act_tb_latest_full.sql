SELECT [fk_financial_year]
      ,[account_type_desc]
      ,[acct_deb_type_desc]
      ,[amt_120days_plus]
      ,[amt_61to90days]
      ,[amt_91to120days]
  FROM [AQTEST].[dbo].[v_sts_act_tb_latest_full]
  where [pk_sts_result_run] = 11731
  and [fk_account_status] = 'A'