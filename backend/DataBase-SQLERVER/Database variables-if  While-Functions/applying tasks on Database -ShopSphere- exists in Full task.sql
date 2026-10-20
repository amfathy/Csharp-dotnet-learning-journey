declare @x date 

update Sales.Customers 
set FirstName = 'AHMED' , @x = BirthDate 
where CustomerId = 2 

select @x 

-----------------------------------------------------------

select @@SERVERNAME 
select @@VERSION

select * from Sales.Customers

create table #t  (phone nvarchar(20) ) ; 

insert into #t 
select Phone 
from Sales.Customers 
where Phone is not null 

select * from  #t 
select count (phone) from #t 

select count(CustomerId) 
from Sales.Customers 
where Phone is null 

-----------------------------------------------------------

declare @x int 
update Sales.Customers 
SET RegisteredAt = CURRENT_TIMESTAMP
where Gender = 'M'
set @x = @@ROWCOUNT
if @x > 0 
	begin 
		select * from Sales.Customers 
		where Gender = 'M'

		select 'Updated'
	end
else 
	select 'An Error Happend'

-----------------------------------------------------------

Begin try 
	Begin Transaction 

		UPDATE Sales.Customers
		SET LastName = 'Ahmed'
		WHERE CustomerId = 3;

		commit 
End try 
Begin Catch 
	Select'Error Happened'
	Rollback 
End catch 

select * from Sales.CustomerAddresses where CityId = 4

---------------------------------------------------------------

-- create a function that take a customer id and return street 

create Function Sales.getStreet(@id int )
returns nvarchar (150)
as 
Begin
	declare @street nvarchar(150) 
	select @street=Street from Sales.CustomerAddresses 
	where CustomerId = @id

	return @street 
END
-----------------
go 
select Sales.getStreet(4983) --for testing 
----------------------------------------------------------------

-- create inline table function  : get employee Info by id 

Create Function Sales.GetInfo (@id int ) 
returns table 
as 
return (select * from Sales.Customers where CustomerId = @id)

go 
 select * from Sales.GetInfo(4983) 
----------------------------------------------------------------
-- create multistatment function 

create function Sales.getins (@format nvarchar (50) ) 
returns @t table (id int , [name] nvarchar (50) ) 
as 
Begin
	if @format = 'FirstName' 
	Begin
		insert into @t 
		select CustomerId , FirstName 
		from Sales.Customers
	End
	else if @format = 'LastName' 
	Begin
		insert into @t 
		select CustomerId , LastName 
		from Sales.Customers
	End
	return 
End 

go 
select * from Sales.getins('LastName')

------------------------------------------------------------------

