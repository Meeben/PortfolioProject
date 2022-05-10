--Inspecting Data
Select * from [PortfolioProject].[dbo].[sales_data_sample]

--Checking unique values
Select distinct [STATUS] from [PortfolioProject].[dbo].[sales_data_sample] --Nice for visual representation
Select distinct YEAR_ID from [PortfolioProject].[dbo].[sales_data_sample]
Select distinct PRODUCTLINE from [PortfolioProject].[dbo].[sales_data_sample] -- Nice for visual representation
Select distinct COUNTRY from [PortfolioProject].[dbo].[sales_data_sample] -- Nice for Visual representation
Select distinct DEALSIZE from [PortfolioProject].[dbo].[sales_data_sample] -- Nice for Visual representation
Select distinct TERRITORY from [PortfolioProject].[dbo].[sales_data_sample] -- Nice for Visual representation
Select distinct [CUSTOMERNAME] from [PortfolioProject].[dbo].[sales_data_sample]




--ANALYSIS
-- Starting with grouping sales by ProductLine
Select [PRODUCTLINE], Sum(sales) Revenue
From [PortfolioProject].[dbo].[sales_data_sample]
Group by [PRODUCTLINE]
Order by 2 desc
-- This shows that Classic Cars is the ProductLine that makes the most Revenue



--Grouping sales by Year
Select [YEAR_ID], Sum(sales) Revenue
From [PortfolioProject].[dbo].[sales_data_sample]
Group by [YEAR_ID]
Order by 2 desc
-- This shows that the most sales was made in 2004 and the least sales was made the following year 2005

-- Finding out the potential reason behind the extremely low sales in 2005
Select distinct [MONTH_ID] from [PortfolioProject].[dbo].[sales_data_sample]
where YEAR_ID = 2005 -- It is seen here that business operations only went on for 5 months, that is January through to May.

--Let's confirm if there was full operation in the previous years
Select distinct [MONTH_ID] from [PortfolioProject].[dbo].[sales_data_sample]
where YEAR_ID = 2004 -- Business operation was ongoing through out the 12months in 2004

Select distinct [MONTH_ID] from [PortfolioProject].[dbo].[sales_data_sample]
where YEAR_ID = 2003  -- Business operation was also ongoing through out the 12 months in 2003
--This confirms that the reason 2005 had the least sales was because they operated for only 5 months.


-- Grouping sales by DealSize
Select DEALSIZE, Sum(sales) Revenue
From [PortfolioProject].[dbo].[sales_data_sample]
Group by DEALSIZE
Order by 2 desc -- This shows that Medium DealSizes brought in the most revenue


---- What was the best Month for Sales in a specific year? How much was earned that month?
select [MONTH_ID], sum(sales) Revenue, count([ORDERNUMBER]) Frequency
from [PortfolioProject].[dbo].[sales_data_sample]
where [YEAR_ID] = 2003 --change year to see the rest
group by [MONTH_ID]
order by 2 desc


-- November appears to be the best month for Sales in the company. 
-- Let's find out the Productline that sold the most in November of each year
select [MONTH_ID], [PRODUCTLINE], sum(sales) Revenue, count([ORDERNUMBER]) Frequency
from [PortfolioProject].[dbo].[sales_data_sample]
where [YEAR_ID] = 2003 and [MONTH_ID] = 11
group by [MONTH_ID], [PRODUCTLINE]
order by 3 desc

select [MONTH_ID], [PRODUCTLINE], sum(sales) Revenue, count([ORDERNUMBER]) Frequency
from [PortfolioProject].[dbo].[sales_data_sample]
where [YEAR_ID] = 2004 and [MONTH_ID] = 11
group by [MONTH_ID], [PRODUCTLINE]
order by 3 desc


-- Finding out, Who is our best customers(Using RFM Analysis)

DROP TABLE IF EXISTS #rfm;
with rfm as
(
	Select 
		[CUSTOMERNAME],
		Sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count([ORDERNUMBER]) Frequency,
		MAX([ORDERDATE]) LastOrderDate,
		(Select MAX([ORDERDATE]) from [PortfolioProject].[dbo].[sales_data_sample]) MaxOrderDate,
		DATEDIFF(DD, MAX([ORDERDATE]), (Select MAX([ORDERDATE]) from [PortfolioProject].[dbo].[sales_data_sample])) Recency
	FROM [PortfolioProject].[dbo].[sales_data_sample]
	Group by [CUSTOMERNAME]
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
cast(rfm_recency as varchar)+cast(rfm_frequency as varchar)+cast(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c

Select [CUSTOMERNAME], rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--What products are most often sold together?

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [PortfolioProject].[dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [PortfolioProject].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [PortfolioProject].[dbo].[sales_data_sample] s
order by 2 desc


-- The city within the USA that made the most Revenue
Select [CITY], sum(Sales) Revenue
From [PortfolioProject].[dbo].[sales_data_sample]
Where [COUNTRY] = 'USA'
Group by [CITY]
Order by 2 desc



