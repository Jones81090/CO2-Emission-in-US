-- EXPLORATORY DATA ANALYSIS
-- Q1 WHAT IS THE OVERALL TREND IN CARBON DIOXIDE EMISSIONS OVER THE YEARS ACROSS ALL STATES?

Select `year`, `state-name`, sum(`value`) as total_emission
from emissions
group by `year`, `state-name`;

-- Q2. ARE THERE ANY SECTORS THAT HAVE SHOWN A SIGNIFICANT INCREASE/DECREASE IN EMISSIONS?
-- To identify sectors that have shown a significant increase or decrease in emissions, 
-- we calculate the percentage change in emissions for each sector over a specified time period. 
-- Sectors with a significant increase or decrease in emissions will have a noticeable percentage change.

With sector_emission as 
( select `sector-name`,
		sum(case when `year` = 1970 then `value` else 0 end) as Emission_1970,
        sum(case when `year` = 2021 then `value` else 0 end) as Emission_2021
from emissions
group by `sector-name`),

Percentagechange as
(select `sector-name`, Emission_1970, Emission_2021, round(((Emission_1970 - Emission_2021)  / Emission_1970) * 100, 2) as percentage_change
from sector_emission),

Significant_change as
(select `sector-name`, Emission_1970, Emission_2021, percentage_change
from Percentagechange
where abs(percentage_change) >= 20 -- Assumimg 20% is the threshold for significant change
)

select `sector-name`, Emission_1970, Emission_2021, percentage_change
from Significant_change;

-- By executing this SQL query, it returns the sectors that have shown a significant increase or decrease in emissions over the specified time period. 

-- Q3. WHICH FUEL TYPES CONTRIBUTE THE MOST TO CARBON DIOXIDE EMISSIONS?
SELECT `fuel-name`, sum(`value`)
from emissions
group by `fuel-name`
having `fuel-name` != 'all fuels'
order by 2 desc;

-- Petroleum contributes the most to carbon dioxide emissions

-- Q4. HAVE THERE BEEN ANY SHIFTS IN THE USAGE OF DIFFERENT FUEL TYPES OVER THE YEARS?

-- calculate total emissions for each fuel type for each year
with fuel_emissions as 
(select `fuel-name`, `year`, sum(`value`) as total_emission
from emissions
group by `fuel-name`, `year`
having `fuel-name` != 'all fuels'),

-- Calculate the percentage of total emissions contributed by each fuel type for each year
percentage_by_fuel as 
(select `fuel-name`, `year`, total_emission, round((total_emission / sum(total_emission) over(partition by `year`)) * 100, 2) as percentage_emission
from fuel_emissions)

-- Final query to analyze shifts in fuel usage over the years
select `fuel-name`, `year`, total_emission, percentage_emission
from percentage_by_fuel;

-- This query returns the percentages of emissions contributed by certain fuel types over time. 
--  We can examine the results of this query to can analyze the shifts in fuel usage over the years. 


-- Q5. CALCULATE THE AVERAGE ANNUAL GROWTH RATE OF CARBON DIOXIDE EMISSIONS FOR EACH STATE?
-- in executing this the coumpound annual growth rate (CAGR) formula was used

with cte as
(
select `state-name`, 
sum(case when `year` = 1970 then `value` else 0 end) as first_year_emission,
sum(case when `year` = 2021 then `value` else 0 end) as last_year_emission,
count(distinct year) as num_years,
pow(sum(case when `year` = 2021 then `value` else 0 end) / sum(case when `year` = 1970 then `value` else 0 end), 1 / 
count(distinct year)) - 1 as avg_annual_growth_rate
from emissions
group by `state-name`)
 
select `state-name`, first_year_emission, last_year_emission, num_years, round(avg_annual_growth_rate, 3) * 100 as avg_annual_growth_rate
from cte
order by 5 desc;

-- This query returns North Dakota has the top state which emmision of CO2 grew by an average of 2.6% annually over the past 52 years 

create view Annual_growth as
select `state-name`, 
sum(case when `year` = 1970 then `value` else 0 end) as first_year_emission,
sum(case when `year` = 2021 then `value` else 0 end) as last_year_emission,
count(distinct year) as num_years,
round(pow(sum(case when `year` = 2021 then `value` else 0 end) / sum(case when `year` = 1970 then `value` else 0 end), 1 / 
count(distinct year)) - 1, 3) * 100 as avg_annual_growth_rate
from emissions
group by `state-name`;

-- Q6. DETERMINE THE YEAR WITH THE HIGHEST EMISSION FOR EACH STATE AND SECTOR
-- To determine this, windows function(partition by) is used 

with cte_1 as
(select `state-name`, `sector-name`, `year`, sum(`value`) as total_emission
from emissions
group by `state-name`, `sector-name`, `year`),

cte_2 as
(select `state-name`, `sector-name`, total_emission, `year`, row_number() over(partition by `state-name`,`sector-name`  order by total_emission desc) as ranking
from cte_1)

select *
from cte_2
where ranking = 1;
-- This query returns the year with the highest emission for each state and sector

-- Q7. DETERMINE THE SECTOR CONTRIBUTING THE MOST TO EMISSIONS FOR EACH STATE OVER THE ENTIRE TIME PERIOD.

with cte_1 as
(select `state-name`, `sector-name`, sum(`value`) as total_emission
from emissions
where `sector-name` != 'Total carbon dioxide emissions from all sectors'
group by `state-name`, `sector-name`),

cte_2 as
(select `state-name`, `sector-name`, total_emission, row_number() over(partition by `state-name` order by total_emission desc) as ranking
from cte_1)

select `state-name`, `sector-name`, total_emission
from cte_2
where ranking = 1;
-- This query returns the sector contributing the most to emissions for each state over the entire time period.

-- Q8. IDENTIFY STATES WHERE EMISSIONS HAVE CONSISTENTLY DECREASED OVER THE PAST DECADE OR PAST 5 YEARS.

with decade_data as
(select `state-name`, `year`, sum(`value`) as total_emission
from emissions
group by `state-name`, `year`
having `year` between 2012 and 2021),

Yearly_change as 
(select d1.`state-name`, d1.`year`, (d1.total_emission - d2.total_emission) as Emission_change 
from decade_data as d1
join decade_data as d2
on d1.`state-name` = d2.`state-name` and d1.`year` = d2.`year` + 1)

select `state-name`
from Yearly_change
group by `state-name`
having count(*) = 9 and sum(case when Emission_change < 0 then 1 else 0 end) = 5 

-- Over the past decade there were no state with consistent decrease in emission. But over the past 5 years the query above returns the list of states with consisitent dectease in Emission



 













    
    


