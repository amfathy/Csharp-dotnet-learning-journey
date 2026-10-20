/*

LEVEL 1 – EASY (syntax recap)

*/

--E01
select * from Geo.Countries 

--E02
select  CustomerId , FirstName , LastName , Email 
from Sales.Customers 
where CustomerId between 1 and 10 

--E03 
select ProductName , UnitPrice 
from Catalog.Products 
where UnitPrice > 1000 
order by UnitPrice DESC ;

--E04 
select distinct Status 
from Sales.Orders 

--E05
select CustomerId , FirstName , LastName
from Sales.Customers 
where Phone is Null 

--E06 
select *
from Catalog.Products 
where ProductName like 'Nova%'

--E07
select OrderId , OrderDate , [Status] 
from Sales.Orders 
where OrderDate >= '2026-06-01'
and OrderDate < '2026-07-01'

select OrderId , OrderDate , [Status] 
from Sales.Orders 
where year(OrderDate) = 2026
and month(OrderDate) = 6 ; 
-- First solution is more friendly with indexing 

--E08
select * 
from Catalog.Products 
where ( UnitPrice between 100 and 200 )
and IsActive = 1 ;

--E09
select *
from Geo.Cities 
where CityName in ( 'Cairo' , 'Dubai' , 'London' ) 

--E10 to E16 same questions 
--------------------------------------------------------------------
/*
	DDL – start the Loyalty module
*/

--E17 
create schema Loyalty;

--E18
create table Loyalty.Tiers
(
	TierId tinyint 
		constraint PK_Tiers primary key , 

	TierName nvarchar(30)
		Constraint UQ_Tiers_TierName unique 
		Constraint NN_Tiers_TierName not null , 

	MinPoint int 
		constraint NN_Tiers_MinPoint not null 
		constraint CK_Tiers_MinPoint check (MinPoint >=0 ) ,

	DiscountPercent Decimal (4,2) 
		constraint NN_Tiers_DiscountPercent not null 
		constraint DF_Tiers_DiscountPercent default 0 , 

);

--E19
create table Loyalty.CustomerPoints 
(
	CustomerId int 
		constraint PK_CustomerPoints primary key
		constraint FK_CustomerPoints_Customers Foreign key 
		references Sales.Customers (CustomerId) ,

	 Points INT
        constraint NN_CustomerPoints_Points not null 
        constraint DF_CustomerPoints_Points
        default 0,

    TierId tinyint  null 
        constraint FK_CustomerPoints_Tiers
        Foreign key references Loyalty.Tiers(TierId),

    UpdatedAt DATETIME2(0)
        constraint NN_CustomerPoints_UpdatedAt
        not null 
        CONSTRAINT DF_CustomerPoints_UpdatedAt
        default SYSDATETIME()

)

--E20
create table Loyalty.PointsLedger 
(
	LedgerId bigint identity(1,1)
		constraint PK_PointsLedger primary key,

	CustomerId int
		constraint NN_PointsLedger_CustomerId not null
		constraint FK_PointsLedger_Customers foreign key
		references Sales.Customers (CustomerId),

	OrderId int null
		constraint FK_PointsLedger_Orders foreign key
		references Sales.Orders (OrderId),

	Points int
		constraint NN_PointsLedger_Points not null,

	Reason varchar(30)
		constraint NN_PointsLedger_Reason not null,

	CreatedAt datetime2(0)
		constraint NN_PointsLedger_CreatedAt
		not null
		constraint DF_PointsLedger_CreatedAt
		default SYSDATETIME()
)

--E21
alter table Loyalty.PointsLedger
add Note nvarchar(200) null
go

alter table Loyalty.PointsLedger
alter column Note nvarchar(300) null
go

alter table Loyalty.PointsLedger
drop column Note
go

--E22
alter table Loyalty.PointsLedger
add constraint CK_PointsLedger_Reason
check
(
	Reason in
	(
		'Purchase',
		'Review',
		'Referral',
		'Adjustment',
		'Redeem',
		'TransferIn',
		'TransferOut',
		'Reversal'
	)
)

/*
	DML basics
*/

--M26
insert into Loyalty.PointsLedger
(
	CustomerId,
	OrderId,
	Points,
	Reason,
	CreatedAt
)
select
	o.CustomerId,
	p.OrderId,
	floor(p.Amount),
	'Purchase',
	p.PaymentDate
from Sales.Payments p
join Sales.Orders o
	on p.OrderId = o.OrderId
where p.Status = 'Completed'

