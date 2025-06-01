select * from data.ps


---Use a recursive CTE to identify potential money laundering chains where money is transferred from one account to another across multiple steps, with all transactions flagged as fraudulent.---
WITH RECURSIVE fraud_chain AS (
    SELECT 
        nameorig AS initial_account, 
        namedest AS next_account, 
        step, 
        amount,
        newbalanceorig
    FROM 
        data.ps
    WHERE 
        isfraud = 1 AND type = 'TRANSFER'
    
    UNION ALL
    
    SELECT 
        fc.initial_account, 
        p.namedest, 
        p.step, 
        p.amount,
        p.newbalanceorig
    FROM 
        fraud_chain fc
    JOIN 
        data.ps p 
    ON 
        fc.next_account = p.nameorig AND fc.step < p.step
    WHERE 
        p.isfraud = 1 AND p.type = 'TRANSFER'
)
SELECT * FROM fraud_chain;


----Use a CTE to calculate the rolling sum of fraudulent transactions for each account over the last 5 steps.--


WITH rolling_fraud AS (
    SELECT 
        nameorig, 
        step, 
        SUM(isfraud) OVER (PARTITION BY nameorig ORDER BY step ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS fraud_rolling_sum
    FROM 
        data.ps
)
SELECT 
    nameorig, 
    step, 
    fraud_rolling_sum
FROM 
    rolling_fraud
WHERE 
    fraud_rolling_sum > 0;

----Use multiple CTEs to identify accounts with suspicious activity, including large transfers, consecutive transactions without balance change, and flagged transactions.--

with large_transfer as (
select 
nameorig,
step,
amount
from
data.ps
where 
type ='TRANSFER' and amount > 500000
),
no_balance_cng as (
select
nameorig,
step,
oldbalanceorg,
newbalanceorig
from
data.ps
where oldbalanceorg = newbalanceorig
),
flagged_trx as(
select
nameorig,
step,
isflaggedfraud
from
data.ps
where isflaggedfraud = 1
)

select 
lt.nameorig
from large_transfer lt
join
no_balance_cng nbc on lt.nameorig= nbc.nameorig and lt.step = nbc.step
join 
flagged_trx ft on lt.nameorig = ft.nameorig and lt.step = ft.step ;

--Write me a query that checks if the computed new_updated_Balance is the same as the actual newbalanceDest in the table. If they are equal,it returns those rows.--
with cte as(
select
amount,
nameorig,
oldbalancedest,
newbalancedest,
(amount+oldbalancedest) as new_updated_balance
from data.ps
)
select * from
cte
where new_updated_balance  = newbalancedest;

-- Find transactions where the destination account had a zero balance before or after the transaction.--

select
nameorig,
namedest,
oldbalancedest,
newbalancedest
amount
from data.ps
where 
oldbalancedest= 0 or newbalancedest = 0;











