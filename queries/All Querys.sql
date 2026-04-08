
create view NewCustomerJourney as
select * from customer_journey
go

create view NewCustomerReviews as
select * from customer_reviews
go

create view NewCustomers as
select * from customers
go

CREATE OR ALTER VIEW dbo.NewEngagementData AS
SELECT
    EngagementID,
    ContentID,
    ContentType,
    Likes,
    EngagementDate,
    CampaignID,
    ProductID,
    Views,
    Clicks,
    CASE
        WHEN Views > 0 THEN CAST(Clicks AS FLOAT) / Views
        ELSE NULL
    END AS CTR
FROM (
    SELECT
        EngagementID,
        ContentID,
        ContentType,
        Likes,
        EngagementDate,
        CampaignID,
        ProductID,

        TRY_CAST(
            LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1)
            AS INT
        ) AS Views,

        TRY_CAST(
            RIGHT(
                ViewsClicksCombined,
                LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)
            )
            AS INT
        ) AS Clicks
    FROM dbo.engagement_data
) t;
GO

create view NewGeography as
select * from geography
go

create view NewProducts as
select * from products
go


UPDATE NewCustomerJourney
SET Stage = LOWER(LTRIM(RTRIM(Stage)));
UPDATE NewEngagementData
SET contentType = LOWER(LTRIM(RTRIM(contentType)));



SELECT * FROM dbo.NewCustomerJourney;
SELECT * FROM dbo.NewCustomerReviews;
SELECT * FROM dbo.NewEngagementData;


SELECT
    CustomerID,
    Stage,
    Action,
    Duration
FROM dbo.NewCustomerJourney
WHERE Duration IS NULL
  AND Action = 'drop-off';


  WITH AvgDurationPerCustomerStage AS (
    SELECT
        CustomerID,
        Stage,
        AVG(Duration * 1.0) AS AvgDuration
    FROM dbo.NewCustomerJourney
    WHERE Duration IS NOT NULL
    GROUP BY CustomerID, Stage
)
UPDATE cj
SET cj.Duration = avgcs.AvgDuration
FROM dbo.NewCustomerJourney cj
JOIN AvgDurationPerCustomerStage avgcs
    ON cj.CustomerID = avgcs.CustomerID
   AND cj.Stage = avgcs.Stage
WHERE cj.Duration IS NULL
  AND cj.Action = 'drop-off';
GO


WITH AvgDurationPerStage AS (
    SELECT
        Stage,
        AVG(Duration * 1.0) AS StageAvgDuration
    FROM dbo.NewCustomerJourney
    WHERE Duration IS NOT NULL
    GROUP BY Stage
)
UPDATE cj
SET cj.Duration = avgst.StageAvgDuration
FROM dbo.NewCustomerJourney cj
JOIN AvgDurationPerStage avgst
    ON cj.Stage = avgst.Stage
WHERE cj.Duration IS NULL
  AND cj.Action = 'drop-off';
GO
SELECT
    COUNT(*) AS RemainingNulls
FROM dbo.NewCustomerJourney
WHERE Duration IS NULL
  AND Action = 'drop-off';


  SELECT TOP 20
    CustomerID,
    Stage,
    Action,
    Duration
FROM dbo.NewCustomerJourney
WHERE Action = 'drop-off'
ORDER BY Duration DESC;



SELECT
    CustomerID,
    ProductID,
    VisitDate,
    Stage,
    Action,
    COUNT(*) AS DuplicateCount
FROM dbo.customer_journey
GROUP BY
    CustomerID,
    ProductID,
    VisitDate,
    Stage,
    Action
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;




SELECT
    CustomerID,
    ProductID,
    ReviewDate,
    ReviewText,
    COUNT(*) AS DuplicateCount
FROM dbo.customer_reviews
GROUP BY
    CustomerID,
    ProductID,
    ReviewDate,
    ReviewText
HAVING COUNT(*) > 1;



SELECT
    ContentID,
    EngagementDate,
    CampaignID,
    ContentType,
    COUNT(*) AS DuplicateCount
FROM dbo.engagement_data
GROUP BY
    ContentID,
    EngagementDate,
    CampaignID,
    ContentType
HAVING COUNT(*) > 1;


SELECT
    Email,
    COUNT(*) AS DuplicateCount
FROM dbo.customers
GROUP BY Email
HAVING COUNT(*) > 1;

SELECT *
FROM dbo.customers
WHERE Email IN (
    SELECT Email
    FROM dbo.customers
    GROUP BY Email
    HAVING COUNT(*) > 1
)
ORDER BY Email;


SELECT
    ProductName,
    Category,
    COUNT(*) AS DuplicateCount
FROM dbo.products
GROUP BY
    ProductName,
    Category
HAVING COUNT(*) > 1;


SELECT
    Country,
    City,
    COUNT(*) AS DuplicateCount
FROM dbo.geography
GROUP BY
    Country,
    City
HAVING COUNT(*) > 1;


WITH DuplicatesCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
               ORDER BY JourneyID
           ) AS rn
    FROM dbo.customer_journey
)
DELETE FROM DuplicatesCTE
WHERE rn > 1;

WITH DuplicatesCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ContentID, EngagementDate, CampaignID, ContentType
               ORDER BY EngagementID
           ) AS rn
    FROM dbo.engagement_data
)
DELETE FROM DuplicatesCTE
WHERE rn > 1;


ALTER TABLE customer_journey
ADD CONSTRAINT PK_CustomerJourney PRIMARY KEY (JourneyID);


ALTER TABLE customer_reviews
ADD CONSTRAINT PK_Customer_Review PRIMARY KEY (ReviewID);


ALTER TABLE customers
ADD CONSTRAINT PK_CustomerID PRIMARY KEY (CustomerID);


ALTER TABLE engagement_data
ADD CONSTRAINT PK_EngagementID PRIMARY KEY (EngagementID);


ALTER TABLE products
ADD CONSTRAINT PK_productID PRIMARY KEY (productID);


ALTER TABLE customer_journey
ADD CONSTRAINT FK_customer_journey
FOREIGN KEY (CustomerID)
REFERENCES customers(CustomerID);


ALTER TABLE customer_journey
ADD CONSTRAINT FK_products_journey
FOREIGN KEY (productID)
REFERENCES products(productID);


ALTER TABLE customer_reviews
ADD CONSTRAINT FK_customer_reviews
FOREIGN KEY (CustomerID)
REFERENCES customers(CustomerID);


ALTER TABLE customer_reviews
ADD CONSTRAINT FK_products_reviews
FOREIGN KEY (productID)
REFERENCES products(productID);



ALTER TABLE customers
ADD CONSTRAINT FK_geography
FOREIGN KEY (GeographyID)
REFERENCES geography(GeographyID);



ALTER TABLE engagement_data
ADD CONSTRAINT FK_productID
FOREIGN KEY (productID)
REFERENCES products(productID);

