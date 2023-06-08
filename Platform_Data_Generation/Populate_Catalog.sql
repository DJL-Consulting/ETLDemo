USE B2B_Platform
GO

declare @CompanyID int = 0,
		@x int,
		@CatalogCnt int,
		@ProductID int,
		@MinProductID int,
		@MaxProductID int;

Set NOCOUNT ON;

TRUNCATE TABLE Catalog;

set @MinProductID = (Select min(ID) from Product);
set @MaxProductID = (select max(ID) from Product);

while (select top 1 ID from Company where Supplier_Flag = 'N' AND ID > @CompanyID) > 0
BEGIN
	set @CompanyID = (Select top 1 ID from Company where Supplier_Flag = 'N' AND ID > @CompanyID ORDER BY ID)

	set @CatalogCnt = B2B_Utils.dbo.Random_Number(30, 800);

	set @x = 1;

	print 'Genrating Catalog for CompanyID ' + cast(@CompanyID as nvarchar);

	while (@x < @CatalogCnt)
	BEGIN 
		set @ProductID = B2B_Utils.dbo.Random_Number(@MinProductID, @MaxProductID)
		INSERT INTO Catalog ([Company_ID], [Product_ID], [Price])
			select @CompanyID, ID, ROUND(cast(B2B_Utils.dbo.Random_Number(80, 300)/100.0 as float) * p.Default_Price, 2) from Product p where ID = @ProductID

		set @x = @x+1;
	END
END

--delete dups
select distinct Product_ID, Company_ID, min(ID) as KeepID, count(*) as cnt
into ##CatalogDups
from Catalog
group by Product_ID, Company_ID
having count(*) > 1
order by cnt desc

delete c
from Catalog c
inner join ##CatalogDups d
	on c.Product_ID = d.Product_ID
	and c.Company_ID = d.Company_ID
	and c.ID <> d.KeepID

drop table ##CatalogDups

