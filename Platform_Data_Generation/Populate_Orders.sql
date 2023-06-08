USE B2B_Platform
go

declare @CompanyID int = 0,
		@x int,
		@y int,
		@OrderCnt int,
		@BatchCnt int,
		@OrderNum int = 0,
		@ItemCnt int,
		@ProductID int,
		@CatalogCnt int,
		@AddressID int,
		@OrderID int,
		@RowID int,
		@CustomerID int,
		@MaxProductID int;


--Run the truncates only to start new order gen
TRUNCATE TABLE Order_Line;
TRUNCATE TABLE Order_Header;

Set NOCOUNT ON;

while (select top 1 ID from Company where Supplier_Flag = 'N' AND ID > @CompanyID) > 0
BEGIN
	set @CompanyID = (Select top 1 ID from Company where Supplier_Flag = 'N' AND ID > @CompanyID ORDER BY ID)

	set @BatchCnt = B2B_Utils.dbo.Random_Number(1, 10);  -- Add between 1 and 10 batches of orders

	set @CatalogCnt = (Select Count(*) from Catalog where Company_ID = @CompanyID);

	set @x = 0;

	while (@x < @BatchCnt)
	BEGIN
		set @OrderCnt = B2B_Utils.dbo.Random_Number(10, 2000);  -- Add between 10 and 2000 orders

		set @x = @x + 1;
		print 'Genrating ' + CAST(@OrderCnt as nvarchar) + ' Orders for CompanyID ' + cast(@CompanyID as nvarchar);

		select B2B_Utils.dbo.Random_Number(1, (select count(*) from Company) ) as Row1, 
				B2B_Utils.dbo.Random_Number(1, (select count(*) from Customer) ) as Row2,
				@OrderNum + ROW_NUMBER() OVER (ORDER BY number) as OrderID,
				B2B_Utils.dbo.Random_Number(1,20) as Item_Cnt
		into #R
		FROM master.dbo.spt_values 
		where type = 'P' and number < @OrderCnt

		INSERT INTO Order_Header([Company_ID], [Customer_ID], [Email], [Ship_To_Address], [Ship_To_City], [Ship_To_State_Province], [Ship_To_Postal_Code], [Ship_To_Country], Order_Date)
		select @CompanyID, 
			   (select sorty.ID from (SELECT c.ID, ROW_NUMBER() OVER (ORDER BY ID ASC) AS RowNum From Customer c) sorty where sorty.RowNum = r.Row2), 
				c.Email, c.Address, c.City, c.State_Province, c.Postal_Code, c.Country, 
				GETDATE() - B2B_Utils.dbo.Random_Number(1, 730) 
		from #R r
		inner join Company c 
			on c.ID = (select sorty.ID from (SELECT c.ID, ROW_NUMBER() OVER (ORDER BY ID ASC) AS RowNum From Company c) sorty where sorty.RowNum = r.row1)

		select r.OrderID, ROW_NUMBER() OVER (ORDER BY v.number) as ID,  B2B_Utils.dbo.Random_Number(1, @CatalogCnt) as ProductNum
		into #R2
		from #r r
		INNER JOIN master.dbo.spt_values v
			on type = 'P' and number < r.Item_Cnt

		insert into Order_Line (Order_ID, Product_ID)
		select R2.OrderID, 
				(select sorty.Product_ID from (SELECT c.Product_ID, ROW_NUMBER() OVER (ORDER BY ID ASC) AS RowNum From Catalog c where Company_ID = @CompanyID) sorty where sorty.RowNum = R2.ProductNum)
		from #R2 r2

		print '>>'+CAST(@@ROWCOUNT as nvarchar)+' Line items created';

		SET @OrderNum = @OrderNum + @OrderCnt


		drop table #R
		drop table #R2
	END
END

PRINT 'Done!';
