----------------- Advanced SQL Project 

-- 1) Creating the database
DROP DATABASE IF EXISTS BankChurnDB;
CREATE DATABASE BankChurnDB;
GO
USE BankChurnDB;



-- 2) Creating tables
-- Customers
DROP TABLE IF EXISTS Customers;
CREATE TABLE Customers (
	CustomerID INT PRIMARY KEY,
	FullName NVARCHAR(120),
	Age INT,
	Gender NVARCHAR(12),
	JoinDate DATE,
	AccountType NVARCHAR(15),
	BranchID INT
);

-- Transactions
DROP TABLE IF EXISTS Transactions;
CREATE TABLE Transactions (
	TransactionId INT PRIMARY KEY,
	CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
	TransactionDate DATE,
	Amount Decimal(12, 2),
	TransactionType NVARCHAR(15),
	Channel NVARCHAR(15)
);

-- Churn
DROP TABLE IF EXISTS Churn;
CREATE TABLE Churn (
	CustomerID INT PRIMARY KEY FOREIGN KEY REFERENCES Customers(CustomerID),
	ChurnFlag BIT,
	ChurnDate DATE
);



-- 3) Insert data to the tables
-- Customers Table  - > Run - > Customers_insert.SQL
-- Transactions Table  - > Run - >  Transactions_insert.SQL
-- Churn Table  - > Run - >  Churn_insert.SQL



-- 4) Initial exploration
-- Display data
SELECT TOP 10 *
FROM Customers;

SELECT TOP 10 *
FROM Transactions;

SELECT TOP 10 *
FROM Churn;


-- No of records
SELECT COUNT(DISTINCT CustomerID) CustID_Cnt
FROM Customers;

SELECT COUNT(DISTINCT TransactionID) TransID_Cnt, COUNT(DISTINCT CustomerID) CustID_Cnt, COUNT(*) Records_Cnt
FROM Transactions;

SELECT COUNT(DISTINCT CustomerID), COUNT(*) Records_Cnt
FROM Churn;

-- Customers
SELECT MIN(Age) Min_age, MAX(Age) Max_age, AVG(Age) Avg_Age, MIN(JoinDate) OldestJoinDate, MAX(JoinDate) NewestJoinDate
FROM Customers;

SELECT Gender, COUNT(*) Cont
FROM Customers
GROUP BY Gender;

SELECT AccountType, COUNT(*) Cont
FROM Customers
GROUP BY AccountType;

-- Transactions
SELECT MIN(Amount) Min_amount, MAX(Amount) Max_amount, AVG(Amount) Avg_amount, MIN(TransactionDate) OldestTransactionDate, MAX(TransactionDate) NewestTransactionDate
FROM Transactions;

SELECT Channel, COUNT(*) Cont
FROM Transactions
GROUP BY Channel;

SELECT TransactionType, COUNT(*) Cont
FROM Transactions
GROUP BY TransactionType;

-- Churn
SELECT MIN(ChurnDate) OldestChurnDate, MAX(ChurnDate) NewestChurnDate
FROM Churn;

SELECT ChurnFlag, COUNT(*) Cont, (CAST(COUNT(*) * 100 AS FLOAT)/(SELECT COUNT(*) FROM Churn))
FROM Churn
GROUP BY ChurnFlag;
-- Out of 10000 Curtomers 1962 Customers have churned



-- 5) Data Validation

-- A) Checking NULL or Missing values
-- Customer
SELECT COUNT(*) CNT
FROM Customers
WHERE FullName IS NULL OR
	  Age IS NULL OR
	  Gender IS NULL OR
	  JoinDate IS NULL OR
	  AccountType IS NULL OR
	  BranchID IS NULL OR
	  CustomerID IS NULL

-- Transaction
SELECT COUNT(*) CNT
FROM Transactions
WHERE TransactionId IS NULL OR
	  CustomerID IS NULL OR
	  TransactionDate IS NULL OR
	  Amount IS NULL OR
	  TransactionType IS NULL OR
	  Channel IS NULL

-- Churn
SELECT COUNT(*) CNT
FROM Churn
WHERE CustomerID IS NULL OR
	  ChurnDate IS NULL OR
	  ChurnFlag IS NULL
-- All active users cannot have ChurnDate

-- B) Checking and Removing Duplicates
-- Customers
SELECT CustomerID, COUNT(*) CNT
FROM Customers
GROUP BY CustomerID
HAVING COUNT(*) > 1
	  
-- Transaction
SELECT TransactionId, COUNT(*) CNT
FROM Transactions
GROUP BY TransactionId
HAVING COUNT(*) > 1	  

-- Churn
SELECT CustomerID, COUNT(*) CNT
FROM Churn
GROUP BY CustomerID
HAVING COUNT(*) > 1	

-- C) Validate ranges
-- Customers
SELECT COUNT(*) CNT
FROM Customers
WHERE Age < 16 OR Age > 100  -- Age has to be between 16 to 100

SELECT COUNT(*) CNT
FROM Customers
WHERE Gender NOT IN ('Male', 'Female') -- Gender can only have 'Male' and 'Female' as categories

SELECT COUNT(*) CNT
FROM Customers
WHERE (YEAR(JoinDate) NOT BETWEEN 2000 AND 2026) OR -- Join year should be in the range of 2000 to 2026
	  DAY(JoinDate) NOT BETWEEN 1 AND 31 OR -- Day part of Date shouldnt be greater 31
	  MONTH(JoinDate) NOT BETWEEN 1 AND 12 -- Month part of Date shouldnt be greater 12

SELECT COUNT(*) CNT
FROM Customers
WHERE AccountType NOT IN ('Current', 'Savings')

-- Transactions
SELECT COUNT(*) CNT
FROM Transactions
WHERE (YEAR(TransactionDate) NOT BETWEEN 2000 AND 2026) OR -- TransactionDate year should be in the range of 2000 to 2026
	  DAY(TransactionDate) NOT BETWEEN 1 AND 31 OR -- Day part of Date shouldnt be greater 31
	  MONTH(TransactionDate) NOT BETWEEN 1 AND 12 -- Month part of Date shouldnt be greater 12

SELECT COUNT(*) CNT
FROM Transactions
WHERE Amount < 0 -- transaction amount cannot be negative

SELECT COUNT(*) CNT -- TransactionType can only have 'Deposit', 'Withdrawal', 'Transfer', 'Payment' as categories
FROM Transactions
WHERE TransactionType NOT IN ('Deposit', 'Withdrawal', 'Transfer', 'Payment') 

SELECT COUNT(*) CNT -- Channel can only have 'Mobile', 'ATM', 'Online', 'Branch' as categories
FROM Transactions
WHERE Channel NOT IN ('Mobile', 'ATM', 'Online', 'Branch')


-- D) Standardize Categorical Data
-- Customers
UPDATE Customers
SET FullName = LOWER(FullName),
	Gender = TRIM(LOWER(Gender)),
	AccountType = TRIM(LOWER(AccountType))

SELECT * FROM Customers

-- Transactions
UPDATE Transactions
SET TransactionType = TRIM(LOWER(TransactionType)),
	Channel = TRIM(LOWER(Channel))

SELECT * FROM Transactions


-- E) Validate Churn
SELECT COUNT(*) CNT
FROM Churn
WHERE ChurnFlag NOT IN (1, 0)

SELECT COUNT(*) CNT
FROM Churn
WHERE (YEAR(ChurnDate) NOT BETWEEN 2000 AND 2026) OR -- ChurnDate year should be in the range of 2000 to 2026
	  DAY(ChurnDate) NOT BETWEEN 1 AND 31 OR -- Day part of Date shouldnt be greater 31
	  MONTH(ChurnDate) NOT BETWEEN 1 AND 12 -- Month part of Date shouldnt be greater 12


WITH ChurnFlagValidate AS (
	SELECT *
	FROM Churn
	WHERE ChurnFlag = 1
)
SELECT *
FROM ChurnFlagValidate
WHERE ChurnDate IS NULL  -- If churned churndate column cannot be null

---

WITH ChurnFlagValidate AS (
	SELECT *
	FROM Churn
	WHERE ChurnFlag = 0
)
SELECT *
FROM ChurnFlagValidate
WHERE ChurnDate IS NOT NULL -- If not churned churndate column must be null


-- 6.1) Combining customer and transaction tables without aggregating to validate join date and tranactiondates
			WITH DATEVALIDATE AS (
					SELECT C.CustomerID,
						   T.TransactionId,
						   C.JoinDate,
						   T.TransactionDate
					FROM Customers C
					LEFT JOIN Transactions T
						ON C.CustomerID = T.CustomerID
			)
			SELECT DISTINCT(TransactionId)
			INTO ##DATEVALIDATEtable
			FROM DATEVALIDATE
			WHERE JoinDate > TransactionDate

-- deleting invalid date observation from transaction table

DELETE FROM Transactions
WHERE TransactionId IN (SELECT TransactionId FROM ##DATEVALIDATEtable)

SELECT COUNT(*)
FROM Transactions
	

-- In all tables all values are in valid range nothing to clean

-- 6.2) Combining tables by aggregating

-- step 1) Grouped by Tranasactions Table by Customer ID and aggregated its data (OldestTransDate,NewestTransDate,TotalAmount,TransCount
--        and made trasactiontype and channel into wide format, and took the percentage of them) to make this table one to one.

-- step 2) then combined customer table, churn table and this new transaction table and create new final table called Churn_Prediction

DROP TABLE IF EXISTS Churn_Prediction;
SELECT C.CustomerID,
	   C.Age,
	   C.Gender,
	   C.JoinDate,
	   C.AccountType,
	   C.BranchID,
	   T.OldestTransDate,
	   T.NewestTransDate,
	   T.TotalAmount,
	   T.TransCount,
	   T.TT_deposite,
	   T.TT_payment,
	   T.TT_transfer,
	   T.TT_withdrawal,
	   T.Channel_atm,
	   T.Channel_branch,
	   T.Channel_mobile,
	   T.Channel_online,
	   CH.ChurnDate,
	   CH.ChurnFlag
INTO Churn_Prediction
FROM Customers C
LEFT JOIN (
			SELECT CustomerID,
				   MIN(TransactionDate) OldestTransDate,
				   MAX(TransactionDate) NewestTransDate,
				   SUM(Amount) TotalAmount,
				   COUNT(Amount) TransCount,
				   CAST(SUM(CASE WHEN TransactionType = 'deposit' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS TT_deposite,
				   CAST(SUM(CASE WHEN TransactionType = 'withdrawal' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS TT_withdrawal,
				   CAST(SUM(CASE WHEN TransactionType = 'payment' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS TT_payment,
				   CAST(SUM(CASE WHEN TransactionType = 'transfer' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS TT_transfer,
				   CAST(SUM(CASE WHEN Channel = 'mobile' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS Channel_mobile,
				   CAST(SUM(CASE WHEN Channel = 'atm' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS Channel_atm,
				   CAST(SUM(CASE WHEN Channel = 'online' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS Channel_online,
				   CAST(SUM(CASE WHEN Channel = 'branch' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,2)) AS Channel_branch
			FROM Transactions
			GROUP BY CustomerID ) AS T
	ON C.CustomerID = T.CustomerID
LEFT JOIN Churn CH
	ON C.CustomerID = CH.CustomerID;


-- No of records
SELECT COUNT(*) CNT
FROM Churn_Prediction


-- checking no.of customers no transaction history
SELECT COUNT(*) CNT
FROM Churn_Prediction
WHERE OldestTransDate IS NULL OR TotalAmount IS NULL

-- validation
SELECT *
FROM Churn_Prediction
WHERE JoinDate > NewestTransDate OR JoinDate > OldestTransDate

-- 7) EDA
-- A) High Risk Customers
-- condition if gap between latest trasaction and todays date is greater than 365 then that customer is in high risk.
SELECT DISTINCT(CustomerID)
FROM Churn_Prediction
WHERE DATEDIFF(Day, NewestTransDate, (SELECT MAX(NewestTransDate) FROM Churn_Prediction)) > 365

-- B) Churn Rate per branch
SELECT BranchID,
	   COUNT(*) CNT, 
	   CAST(SUM(CASE WHEN ChurnFlag = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS DECIMAL(5,4)) AS Rate
FROM Churn_Prediction
GROUP BY BranchID
ORDER BY Rate DESC

-- C) Age Segmentaion
WITH Agecat AS (
	SELECT *,
			(CASE WHEN Age < 30 THEN 'Young'
				 WHEN Age BETWEEN 30 AND 50 THEN 'Middle'
				 ELSE 'Senior'
				 END) AS Age_Cat
	FROM Churn_Prediction
)
SELECT Age_Cat,
	   COUNT(*) CNT,
	   CAST(COUNT(*) * 1.0 / (SELECT COUNT(*) FROM Churn_Prediction) AS DECIMAL(5,4)) AS Ratio
FROM Agecat
GROUP BY Age_Cat
ORDER BY Ratio DESC;

-- updating exisiting table with age category
ALTER TABLE Churn_Prediction ADD AgeGroup VARCHAR(20);
UPDATE Churn_Prediction
SET AgeGroup =
    CASE 
        WHEN Age < 30 THEN 'Young'
        WHEN Age BETWEEN 30 AND 50 THEN 'Middle'
        ELSE 'Senior'
    END;

-- D) Deposite vs Withdraw ratio
WITH WithDipRatio AS (
	SELECT TransactionType, COUNT(*) CNT
	FROM Transactions
	WHERE TransactionType = 'Deposit' OR TransactionType = 'withdrawal'
	GROUP BY TransactionType
)
SELECT SUM(CASE WHEN TransactionType = 'Deposit' THEN CNT END) * 1.0 / SUM(CASE WHEN TransactionType = 'withdrawal' THEN CNT END)
FROM WithDipRatio;

-- ratio is almost 1:1

-- E) Top 3 transactions for customers

WITH TOPTABLE AS (
	SELECT C.CustomerID,
		   T.TransactionDate,
		   T.Amount
	FROM Customers C
	LEFT JOIN Churn Ch
		ON C.CustomerID = Ch.CustomerID
	LEFT JOIN Transactions T
		ON C.CustomerID = T.CustomerID
)
SELECT *,
		DENSE_RANK() OVER (
				PARTITION BY CustomerID
				ORDER BY Amount DESC
				) AS Rank
INTO ##newtable
FROM TOPTABLE

SELECT *
FROM ##newtable
WHERE RANK < 4
ORDER BY CustomerID 


-- 9) Advanced Analytics
-------- Cumalative Transaction Amount per Customer
SELECT *,
		SUM(Amount) OVER (				
						PARTITION BY CustomerID
						ORDER BY TransactionDate
				) AS CumalativeAmount
FROM ##newtable;


------- Churn Customers with Above Average Deposits
WITH desposit AS (
	SELECT C.CustomerID,
		   T.TransactionDate,
		   T.Amount,
		   Ch.ChurnFlag,
		   T.TransactionType
	FROM Customers C
	LEFT JOIN Churn Ch
		ON C.CustomerID = Ch.CustomerID
	LEFT JOIN Transactions T
		ON C.CustomerID = T.CustomerID
	WHERE T.TransactionType = 'deposit'
)
SELECT *
INTO ##newtable3
FROM desposit

-- TABLE WITH ALL AVERAGES
SELECT *,
		AVG(Amount) OVER () AS OverallAVG,
		AVG(Amount) OVER (PARTITION BY CustomerID) AS CUSTOMERAVG
INTO ##newtable4
FROM ##newtable3

-- FINAL TABLE
SELECT DISTINCT(CustomerID)
FROM ##newtable4
WHERE ChurnFlag = 1 AND CUSTOMERAVG > OverallAVG
ORDER BY CustomerID


------- Churn Customers with <3 Transactions in Last 6 months
WITH FILTER1 AS (
	SELECT C.CustomerID,
		   T.TransactionDate,
		   T.Amount,
		   Ch.ChurnFlag,
		   T.TransactionType
	FROM Customers C
	LEFT JOIN Churn Ch
		ON C.CustomerID = Ch.CustomerID
	LEFT JOIN Transactions T
		ON C.CustomerID = T.CustomerID
)
SELECT *,
		COUNT(*) OVER (PARTITION BY CustomerID) AS CNT,
		DATEADD(MONTH, -6, GETDATE()) datebeforesixmonth
INTO ##newtable5
FROM FILTER1

-- final table
SELECT *
FROM ##newtable5
WHERE ChurnFlag = 1 AND CNT < 3 AND TransactionDate > datebeforesixmonth



-- 10) Univariate Analysis
SELECT *
FROM Churn_Prediction

-- Numerical
-- Age
SELECT MIN(Age) MINAGE, MAX(Age) MAXAGE, AVG(Age) AVGAGE, STDEV(Age) STDAGE
FROM Churn_Prediction

-- Amount
SELECT MIN(TotalAmount) MINTotalAmount, MAX(TotalAmount) MAXTotalAmount, AVG(TotalAmount) AVGTotalAmount, STDEV(TotalAmount) STDTotalAmount
FROM Churn_Prediction

-- tranaction count
SELECT MIN(TransCount) MINTransCount, MAX(TransCount) MAXTransCount, AVG(TransCount) AVGTransCount, STDEV(TransCount) STDTransCount
FROM Churn_Prediction

-- TT_deposit
SELECT MIN(TT_deposite) MINTT_deposite, MAX(TT_deposite) MAXTT_deposite, AVG(TT_deposite) AVGTT_deposite, STDEV(TT_deposite) STDTT_deposite
FROM Churn_Prediction

-- TT_deposit
SELECT MIN(TT_payment) MINTT_payment, MAX(TT_payment) MAXTT_payment, AVG(TT_payment) AVGTT_payment, STDEV(TT_payment) STDTT_payment
FROM Churn_Prediction

-- TT_deposit
SELECT MIN(TT_transfer) MINTT_transfer, MAX(TT_transfer) MAXTT_transfer, AVG(TT_transfer) AVGTT_transfer, STDEV(TT_transfer) STDTT_transfer
FROM Churn_Prediction

-- TT_deposit
SELECT MIN(TT_withdrawal) MINTT_withdrawal, MAX(TT_withdrawal) MAXTT_withdrawal, AVG(TT_withdrawal) AVGTT_withdrawal, STDEV(TT_withdrawal) STDTT_withdrawal
FROM Churn_Prediction


-- Channel_atm
SELECT MIN(Channel_atm) MINChannel_atm, MAX(Channel_atm) MAXChannel_atm, AVG(Channel_atm) AVGChannel_atm, STDEV(Channel_atm) STDChannel_atm
FROM Churn_Prediction

-- Channel_branch
SELECT MIN(Channel_branch) MINChannel_branch, MAX(Channel_branch) MAXChannel_branch, AVG(Channel_branch) AVGChannel_branch, STDEV(Channel_branch) STDChannel_branch
FROM Churn_Prediction

-- Channel_mobile
SELECT MIN(Channel_mobile) MINChannel_mobile, MAX(Channel_mobile) MAXChannel_mobile, AVG(Channel_mobile) AVGChannel_mobile, STDEV(Channel_mobile) STDChannel_mobile
FROM Churn_Prediction

-- Channel_online
SELECT MIN(Channel_online) MINChannel_online, MAX(Channel_online) MAXChannel_online, AVG(Channel_online) AVGChannel_online, STDEV(Channel_online) STDChannel_online
FROM Churn_Prediction

-- Joindate
SELECT MIN(JoinDate) MINJoinDate, MAX(JoinDate) MAXJoinDate
FROM Churn_Prediction

-- newest transactiondate
SELECT MIN(NewestTransDate) MINNewestTransDate, MAX(NewestTransDate) MAXNewestTransDate
FROM Churn_Prediction

-- newest transactiondate
SELECT MIN(OldestTransDate) MINOldestTransDate, MAX(OldestTransDate) MAXOldestTransDate
FROM Churn_Prediction

-- churndate
SELECT MIN(ChurnDate) MINChurnDate, MAX(ChurnDate) MAXChurnDate
FROM Churn_Prediction



-- Categorical
-- gender
SELECT Gender, COUNT(*) Cont
FROM Churn_Prediction
GROUP BY Gender;

-- AccountType
SELECT AccountType, COUNT(*) Cont
FROM Churn_Prediction
GROUP BY AccountType;

-- branch id
SELECT BranchID, COUNT(*) Cont
FROM Churn_Prediction
GROUP BY BranchID
ORDER BY COUNT(*) DESC;

-- Agecategory
SELECT AgeGroup, COUNT(*) Cont
FROM Churn_Prediction
GROUP BY AgeGroup
ORDER BY COUNT(*) DESC;

-- Churnflag
SELECT ChurnFlag, COUNT(*) Cont
FROM Churn_Prediction
GROUP BY ChurnFlag




-- 11) Bi-Variate Analysis
-- Numerical vs Numerical

--|| Age vs TotalTransAmount
--|| Withdrawal perc vs Age




-- Categorical vs Categorical

--|| AgeGroup vs Churn

SELECT AgeGroup,
	   SUM(CASE WHEN ChurnFlag = 1 THEN 1 ELSE 0 END) '1',
	   SUM(CASE WHEN ChurnFlag = 0 THEN 1 ELSE 0 END) '0',
	   COUNT(*) Total
FROM Churn_Prediction
GROUP BY AgeGroup


--|| Gender vs Churn

SELECT Gender,
	   SUM(CASE WHEN ChurnFlag = 1 THEN 1 ELSE 0 END) '1',
	   SUM(CASE WHEN ChurnFlag = 0 THEN 1 ELSE 0 END) '0',
	   COUNT(*) Total
FROM Churn_Prediction
GROUP BY Gender

--|| BranchID vs Churn

SELECT BranchID,
	   SUM(CASE WHEN ChurnFlag = 1 THEN 1 ELSE 0 END) '1',
	   SUM(CASE WHEN ChurnFlag = 0 THEN 1 ELSE 0 END) '0',
	   COUNT(*) Total
FROM Churn_Prediction
GROUP BY BranchID



-- Categorical vs Numerical

--|| Age vs Churn

SELECT ChurnFlag, MIN(Age) MINAGE, MAX(Age) MAXAGE, AVG(Age) AVGAGE, STDEV(Age) STDAGE
FROM Churn_Prediction
GROUP BY ChurnFlag

--|| TotalTransactionAmount vs Churn

SELECT ChurnFlag, MIN(TotalAmount) MINTotalAmount, MAX(TotalAmount) MAXTotalAmount, AVG(TotalAmount) AVGTotalAmount, STDEV(TotalAmount) STDTotalAmount
FROM Churn_Prediction
GROUP BY ChurnFlag

--|| transferratio vs Churn

SELECT ChurnFlag, MIN(TT_transfer) MINTT_transfer, MAX(TT_transfer) MAXTT_transfer, AVG(TT_transfer) AVGTT_transfer, STDEV(TT_transfer) STDTT_transfer
FROM Churn_Prediction
GROUP BY ChurnFlag




-- moving master table data to csv
SELECT *
FROM Churn_Prediction


--- Calculate RFM Base Table

WITH RFM AS (
    SELECT 
        CustomerID,
        DATEDIFF(DAY, MAX(NewestTransDate), GETDATE()) AS Recency,
        SUM(TransCount) AS Frequency,
        SUM(TotalAmount) AS Monetary
    FROM Churn_Prediction
    GROUP BY CustomerID
)
SELECT * INTO RFM_Table FROM RFM;

-- Assign RFM Scores Using NTILE()
DROP TABLE IF EXISTS ##RFM_Scored;
SELECT *,
       NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
       NTILE(5) OVER (ORDER BY Frequency) AS F_Score,
       NTILE(5) OVER (ORDER BY Monetary) AS M_Score
INTO ##RFM_Scored
FROM RFM_Table;


--- Create RFM Segment Label
ALTER TABLE ##RFM_Scored ADD RFM_Segment VARCHAR(20);

UPDATE ##RFM_Scored
SET RFM_Segment =
    CASE 
        WHEN R_Score >=4 AND F_Score >=4 AND M_Score >=4 THEN 'Champions'
        WHEN R_Score >=3 AND F_Score >=3 THEN 'Loyal'
        WHEN R_Score =1 AND F_Score <=2 THEN 'At Risk'
        ELSE 'Regular'
    END;


--- Top RFM Segments
SELECT RFM_Segment, COUNT(*) AS CustomerCount
FROM ##RFM_Scored
GROUP BY RFM_Segment
ORDER BY CustomerCount DESC;




