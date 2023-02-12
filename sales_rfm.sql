
---Analysis
---Productline and total sales

select PRODUCTLINE,SUM(SALES) AS REVENUE FROM [sales].[dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc
;

select YEAR_ID,SUM(SALES) AS REVENUE FROM [sales].[dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc
;

select DEALSIZE,SUM(SALES) AS REVENUE FROM [sales].[dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc
;
---2004 IS THE BEST YEAR
SELECT MONTH_ID,SUM(SALES) REVENUE,COUNT(ORDERNUMBER)FREQUENCY FROM [sales].[dbo].[sales_data_sample]
WHERE YEAR_ID='2004'
GROUP BY MONTH_ID
ORDER BY 3 DESC;

---NOVEMEBER WAS THE BEST MONHT
SELECT MONTH_ID,PRODUCTLINE,COUNT(ORDERNUMBER)FREQUENCY FROM [sales].[dbo].[sales_data_sample]
WHERE YEAR_ID='2004' AND MONTH_ID='11'
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY 3 DESC;

---RFM 
DROP TABLE IF EXISTS #rfm;
;with rfm as(
SELECT CUSTOMERNAME,
		SUM(SALES) monetaryValue,
		avg(sales) avgMonetaryValue,
		count(ordernumber) frequency,
		max(orderdate) lastOrderDate,
		(select max(orderdate) from[sales].[dbo].[sales_data_sample] ) as maxOrderDate,
		DATEDIFF(DD,max(orderdate) ,(select max(orderdate)from[sales].[dbo].[sales_data_sample])) AS recency
		from [sales].[dbo].[sales_data_sample]
		group by customername),
		rfm_calc as(

select r.*,
NTILE(4) over(order by r.recency desc) as rfm_recency,
NTILE(4) over(order by r.frequency) as rfm_frequency,
NTILE(4) over(order by r.monetaryValue) as rfm_monency
from rfm as r
)

select c.*,cast(c.rfm_recency as varchar)+cast(c.rfm_frequency as varchar)+cast(c.rfm_monency as varchar) as rfm_cell_string,
c.rfm_recency+c.rfm_frequency+c.rfm_monency as rfm_cell
into #rfm
from rfm_calc c;

select CUSTOMERNAME,rfm_recency,rfm_frequency,rfm_monency,
case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from #rfm;



select distinct ordernumber,stuff((SELECT ','+PRODUCTCODE  FROM [sales].[dbo].[sales_data_sample] p
WHERE ORDERNUMBER IN(
SELECT ORDERNUMBER FROM(
select ORDERNUMBER,count(*) as rn
from [sales].[dbo].[sales_data_sample]
where status='SHIPPED'
group by ORDERNUMBER) AS M
WHERE RN=2) and s.ordernumber=p.ORDERNUMBER
for xml path('')),1,1,'') productCodes
from  [sales].[dbo].[sales_data_sample] s
order by 2 desc