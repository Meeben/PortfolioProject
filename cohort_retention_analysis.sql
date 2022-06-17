---Data Cleaning
---Total Records = 541,909
---135,080 records have no CustomerID
---406,829 records have CustomerID

;with online_retail as ---cte 1
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [PortfolioProject].[dbo].[Online_Retail_Project]
	  WHERE CustomerID is not null 
)
, quantity_unit_price as ---cte 2
(

	---397,884 records with quantity and unitprice
	SELECT * 
	FROM online_retail
	WHERE Quantity > 0 and UnitPrice > 0 ---This is to remove all the records that have Quantity and UnitPrice less than 0
)
, dup_check as ---cte 3
(
	---Checking for duplicates
	SELECT * , ROW_NUMBER() OVER (PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate)flag_dup
	FROM quantity_unit_price
)
---5,215 duplicate records
---392,669 clean data
SELECT * 
INTO #main_online_retail ---Parsing data into a temp table.
FROM dup_check
WHERE flag_dup = 1

---Clean Data
----Begin Cohort Analysis
SELECT * FROM #main_online_retail

---Metrics needed for the Cohort Analysis
--- 1. Unique Identifier (CustomerID)
--- 2. Initial Start Date (First Invoice Date)
--- 3. Revenue Date

SELECT
	CustomerID,
	min(InvoiceDate) first_purchase_date,
	DATEFROMPARTS(YEAR(MIN(InvoiceDate)), month(MIN(InvoiceDate)), 1) Cohort_Date
INTO #cohort
FROM #main_online_retail
GROUP BY CustomerID


SELECT *
FROM #cohort

---Creating the Cohort Index.
SELECT
	mmm.*,
	cohort_index = year_diff * 12 + month_diff + 1
INTO #cohort_retention
FROM
	(
		SELECT
			mm.*,
			year_diff = invoice_year -cohort_year,
			month_diff = invoice_month - cohort_month
		FROM
			(
				SELECT
					m.*,
					c.Cohort_Date,
					year(m.InvoiceDate) invoice_year,
					month(m.InvoiceDate) invoice_month,
					year(c.Cohort_Date) cohort_year,
					month(c.Cohort_Date) cohort_month
				FROM #main_online_retail m
				LEFT JOIN #cohort c
					ON m.CustomerID = c.CustomerID
			)mm
	)mmm

--- Pivot data to see the cohort table.
SELECT *
INTO #cohort_pivot
FROM(
	SELECT DISTINCT
		CustomerID,
		Cohort_Date,
		cohort_index
	FROM #cohort_retention
)tbl
pivot(
	Count(CustomerID)
	for Cohort_index in
		(
		[1],
		[2],
		[3],
		[4],
		[5],
		[6],
		[7],
		[8],
		[9],
		[10],
		[11],
		[12],
		[13])
) as pivot_table
---ORDER BY Cohort_Date

SELECT *
FROM #cohort_pivot
ORDER BY Cohort_Date

SELECT Cohort_Date, 
	1.0*[1]/[1] * 100 as [1],
	1.0*[2]/[1] * 100 as [2],
	1.0*[3]/[1] * 100 as [3],
	1.0*[4]/[1] * 100 as [4],
	1.0*[5]/[1] * 100 as [5],
	1.0*[6]/[1] * 100 as [6],
	1.0*[7]/[1] * 100 as [7],
	1.0*[8]/[1] * 100 as [8],
	1.0*[9]/[1] * 100 as [9],
	1.0*[10]/[1] * 100 as [10],
	1.0*[11]/[1] * 100 as [11],
	1.0*[12]/[1] * 100 as [12],
	1.0*[13]/[1] * 100 as [13]
FROM #cohort_pivot
ORDER BY Cohort_Date
