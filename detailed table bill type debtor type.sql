SELECT 
    [fk_financial_year] AS [Year],
	[bill_type_desc] as [Bill Type],
    [acct_deb_type_desc] AS [Acct Debtor],
    SUM([amt_61to90days]) AS [90 Days],
    SUM([amt_91to120days]) AS [120 Days],
    SUM([amt_120days_plus]) AS [120+ Days],
	sum([amt_365days_plus]) as [365+ Days]
FROM 
    [AQTEST].[dbo].[v_sts_act_tb_latest_full]
WHERE 
    [pk_sts_result_run] = 11731
    --AND [fk_account_status] = 'A'
GROUP BY 
    [fk_financial_year],
	[bill_type_desc],
    [acct_deb_type_desc]
ORDER BY 
    [fk_financial_year],
	[bill_type_desc],
    [acct_deb_type_desc];
