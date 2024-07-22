#Un reporte que muestre nombre del cliente, número de la orden, nombre producto, cantidad comprada,
#empresa que lo produce, categoría a la que pertenece el producto.

SELECT 
    soh.SalesOrderNumber AS OrderNumber,
    p.Name AS ProductName,
    v.Name AS VendorName,
    pc.Name AS ProductCategory,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS CustomerName,
    a.City AS CustomerCity,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS EmployeeName,
    a2.City AS EmployeeRegion, -- Utilizamos la ciudad del empleado como región de ejemplo
    soh.TotalDue AS OrderTotal
FROM 
    sales_salesorderheader soh
JOIN 
    sales_salesorderdetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    production_product p ON sod.ProductID = p.ProductID
JOIN 
    purchasing_productvendor pv ON p.ProductID = pv.ProductID
JOIN 
    purchasing_vendor v ON pv.BusinessEntityID = v.BusinessEntityID
JOIN 
    production_productsubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN 
    production_productcategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
JOIN 
    sales_customer c ON soh.CustomerID = c.CustomerID
JOIN 
    person_address a ON c.StoreID = a.AddressID
JOIN 
    sales_salesperson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN 
    person_person pp ON sp.BusinessEntityID = pp.BusinessEntityID
JOIN 
    humanresources_employeedepartmenthistory edh ON sp.BusinessEntityID = edh.BusinessEntityID
JOIN 
    humanresources_department d ON edh.DepartmentID = d.DepartmentID
JOIN 
    person_address a2 ON sp.BusinessEntityID = a2.AddressID; -- Utilizamos la dirección del empleado como región de ejemplo

#UN reporte que muestre empleado, cliente, ciudad del cliente, producto, valor de la orden para las órdenes cuyo valor de venta sea mayor a 300

SELECT
    soh.SalesOrderID,
    soh.TotalDue,
    sod.ProductID,
    prod.Name AS ProductName,
    cust.CustomerID,
    cust.PersonID,
    custPerson.FirstName + ' ' + custPerson.LastName AS CustomerName,
    addr.AddressLine1,
    addr.City,
    state.Name AS StateProvince,
    country.Name AS CountryRegion,
    emp.BusinessEntityID AS EmployeeID,
    empPerson.FirstName + ' ' + empPerson.LastName AS EmployeeName
FROM
    sales_salesorderheader soh
JOIN
    sales_salesorderdetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN
    production_product prod ON sod.ProductID = prod.ProductID
JOIN
    sales_customer cust ON soh.CustomerID = cust.CustomerID
JOIN
    person_person custPerson ON cust.PersonID = custPerson.BusinessEntityID
JOIN
    person_businessentityaddress bea ON cust.PersonID = bea.BusinessEntityID
JOIN
    person_address addr ON bea.AddressID = addr.AddressID
JOIN
    person_stateprovince state ON addr.StateProvinceID = state.StateProvinceID
JOIN
    person_countryregion country ON state.CountryRegionCode = country.CountryRegionCode
LEFT JOIN
    sales_salesperson sp ON soh.SalesPersonID = sp.BusinessEntityID
LEFT JOIN
    humanresources_employee emp ON sp.BusinessEntityID = emp.BusinessEntityID
LEFT JOIN
    person_person empPerson ON emp.BusinessEntityID = empPerson.BusinessEntityID
WHERE
    soh.TotalDue > 300;
    
#Un reporte para determinar el valor vendido por cada empleado por cada producto que vendió (es decir, nombre empleado, nombre producto, total vendido). 
#(Nota: total vendido sumo el valor de la venta de cada producto. Valor venta = cantidad x precio unitario).

SELECT
    CONCAT(empPerson.FirstName, ' ', empPerson.LastName) AS EmployeeName,
    prod.Name AS ProductName,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalSold
FROM
    sales_salesorderheader soh
JOIN
    sales_salesorderdetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN
    production_product prod ON sod.ProductID = prod.ProductID
LEFT JOIN
    sales_salesperson sp ON soh.SalesPersonID = sp.BusinessEntityID
LEFT JOIN
    humanresources_employee emp ON sp.BusinessEntityID = emp.BusinessEntityID
LEFT JOIN
    person_person empPerson ON emp.BusinessEntityID = empPerson.BusinessEntityID
GROUP BY
    empPerson.FirstName, empPerson.LastName, prod.Name
ORDER BY
    EmployeeName, ProductName;

#Seleccione el nombre del cliente y la dirección del cliente de todos los clientes con pedidos enviados mediante Speedy Express.

SELECT
    CONCAT(custPerson.FirstName, ' ', custPerson.LastName) AS CustomerName,
    addr.AddressLine1 AS Address,
    addr.City,
    state.Name AS StateProvince,
    country.Name AS CountryRegion
FROM
    sales_salesorderheader soh
JOIN
    purchasing_shipmethod sm ON soh.ShipMethodID = sm.ShipMethodID
JOIN
    sales_customer cust ON soh.CustomerID = cust.CustomerID
JOIN
    person_person custPerson ON cust.PersonID = custPerson.BusinessEntityID
JOIN
    person_businessentityaddress bea ON cust.PersonID = bea.BusinessEntityID
JOIN
    person_address addr ON bea.AddressID = addr.AddressID
JOIN
    person_stateprovince state ON addr.StateProvinceID = state.StateProvinceID
JOIN
    person_countryregion country ON state.CountryRegionCode = country.CountryRegionCode
WHERE
    sm.Name = 'XRQ - TRUCK GROUND';

#Una consulta que muestre los mejores clientes en función del monto total de compras mostrando en una columna el valor bruto y en otra el valor con descuentos,
#si los tuvo.

SELECT
    cust.CustomerID,
    CONCAT(custPerson.FirstName, ' ', custPerson.LastName) AS CustomerName,
    SUM(soh.TotalDue) AS TotalGrossAmount,
    SUM(CASE 
            WHEN sod.SpecialOfferID IS NOT NULL THEN sod.OrderQty * sod.UnitPrice * (1 - sod.UnitPriceDiscount)
            ELSE sod.OrderQty * sod.UnitPrice
        END) AS TotalNetAmount
FROM
    sales_salesorderheader soh
JOIN
    sales_salesorderdetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN
    sales_customer cust ON soh.CustomerID = cust.CustomerID
JOIN
    person_person custPerson ON cust.PersonID = custPerson.BusinessEntityID
GROUP BY
    cust.CustomerID, custPerson.FirstName, custPerson.LastName
ORDER BY
    TotalGrossAmount DESC;

#Una consulta que muestre los clientes que se hayan demorado mas de 15 días entre un pedido y otro. sin importar la fecha

WITH OrderDates AS (
    SELECT
        cust.CustomerID,
        custPerson.FirstName,
        custPerson.LastName,
        soh.SalesOrderID,
        soh.OrderDate,
        ROW_NUMBER() OVER (PARTITION BY cust.CustomerID ORDER BY soh.OrderDate) AS rn
    FROM
        sales_salesorderheader soh
    JOIN
        sales_customer cust ON soh.CustomerID = cust.CustomerID
    JOIN
        person_person custPerson ON cust.PersonID = custPerson.BusinessEntityID
),
DateDifferences AS (
    SELECT
        a.CustomerID,
        a.FirstName,
        a.LastName,
        a.SalesOrderID AS OrderID1,
        a.OrderDate AS OrderDate1,
        b.SalesOrderID AS OrderID2,
        b.OrderDate AS OrderDate2,
        DATEDIFF(b.OrderDate, a.OrderDate) AS DaysBetween
    FROM
        OrderDates a
    JOIN
        OrderDates b ON a.CustomerID = b.CustomerID AND a.rn = b.rn - 1
)
SELECT
    CustomerID,
    FirstName,
    LastName,
    OrderID1,
    OrderDate1,
    OrderID2,
    OrderDate2,
    DaysBetween
FROM
    DateDifferences
WHERE
    DaysBetween > 15;
    
#Listar por categoría los productos vendidos por mes (nombre mes en español) indicando el total de ventas y ordenando de forma descendente
    
    CREATE TABLE month_translation (
    month_number INT,
    month_name_es VARCHAR(20)
);

INSERT INTO month_translation (month_number, month_name_es) VALUES
(1, 'Enero'),
(2, 'Febrero'),
(3, 'Marzo'),
(4, 'Abril'),
(5, 'Mayo'),
(6, 'Junio'),
(7, 'Julio'),
(8, 'Agosto'),
(9, 'Septiembre'),
(10, 'Octubre'),
(11, 'Noviembre'),
(12, 'Diciembre');

SELECT
    pc.Name AS ProductCategory,
    mt.month_name_es AS MonthName,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales
FROM
    sales_salesorderheader soh
JOIN
    sales_salesorderdetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN
    production_product pp ON sod.ProductID = pp.ProductID
JOIN
    production_productsubcategory pps ON pp.ProductSubcategoryID = pps.ProductSubcategoryID
JOIN
    production_productcategory pc ON pps.ProductCategoryID = pc.ProductCategoryID
JOIN
    month_translation mt ON MONTH(soh.OrderDate) = mt.month_number
GROUP BY
    pc.Name,
    mt.month_name_es,
    YEAR(soh.OrderDate),
    MONTH(soh.OrderDate)
ORDER BY
    pc.Name,
    YEAR(soh.OrderDate),
    MONTH(soh.OrderDate);

#Realice una consulta que muestre el total de pagos realizados por cada cliente y agrúpelos en 3 categorías: oro plata y broce de acuerdo con el valor más alto vendido
#y tomando 3 intervalos. Muestre nombre completo del cliente y la ciudad a la que pertenece y la categoría.

-- Paso 1: Calcular el total de ventas realizadas por cada cliente
WITH TotalSales AS (
    SELECT
        cust.CustomerID,
        CONCAT(custPerson.FirstName, ' ', custPerson.LastName) AS CustomerName,
        CONCAT(addr.City, ', ', sp.Name) AS City,
        SUM(sod.OrderQty * sod.UnitPrice) AS TotalAmount
    FROM
        sales_salesorderheader soh
    JOIN
        sales_salesorderdetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN
        sales_customer cust ON soh.CustomerID = cust.CustomerID
    JOIN
        person_person custPerson ON cust.PersonID = custPerson.BusinessEntityID
    JOIN
        person_businessentity be ON cust.PersonID = be.BusinessEntityID
    JOIN
        person_businessentityaddress beAddr ON be.BusinessEntityID = beAddr.BusinessEntityID
    JOIN
        person_address addr ON beAddr.AddressID = addr.AddressID
    JOIN
        person_stateprovince sp ON addr.StateProvinceID = sp.StateProvinceID
    GROUP BY
        cust.CustomerID, custPerson.FirstName, custPerson.LastName, addr.City, sp.Name
),

-- Paso 2: Clasificar a los clientes en categorías
CategorizedSales AS (
    SELECT
        CustomerID,
        CustomerName,
        City,
        TotalAmount,
        CASE
            WHEN TotalAmount >= (SELECT MAX(TotalAmount) * 0.75 FROM TotalSales) THEN 'Oro'
            WHEN TotalAmount >= (SELECT MAX(TotalAmount) * 0.50 FROM TotalSales) THEN 'Plata'
            ELSE 'Bronce'
        END AS Category
    FROM
        TotalSales
)

-- Paso 3: Mostrar el resultado final
SELECT
    CustomerName,
    City,
    Category
FROM
    CategorizedSales
ORDER BY
    Category DESC, TotalAmount DESC;

#Una consulta que muestre los empleados que con los dos pedidos más altos que hayan atendido por mes. Mostrar nombre completo empelado, numero de orden, valor de la orden y mes.

-- Paso 1: Calcular el valor de las órdenes y extraer el mes y año
SELECT
    soh.SalesOrderID,
    soh.OrderDate,
    DATE_FORMAT(soh.OrderDate, '%Y-%m') AS OrderMonth, -- Año y mes en formato YYYY-MM
    (sod.OrderQty * sod.UnitPrice) AS OrderValue,
    soh.SalesPersonID
INTO @orderValues
FROM
    sales_salesorderheader soh
JOIN
    sales_salesorderdetail sod ON soh.SalesOrderID = sod.SalesOrderID;

-- Paso 2: Determinar los dos pedidos más altos por empleado y mes
SET @rank := 0;
SET @currentEmployee := NULL;
SET @currentMonth := NULL;

SELECT
    SalesPersonID,
    SalesOrderID,
    OrderValue,
    OrderMonth,
    @rank := IF(@currentEmployee = SalesPersonID AND @currentMonth = OrderMonth, @rank + 1, 1) AS Rank,
    @currentEmployee := SalesPersonID,
    @currentMonth := OrderMonth
FROM
    @orderValues
ORDER BY
    SalesPersonID, OrderMonth, OrderValue DESC;

-- Paso 3: Mostrar el nombre completo del empleado, número de orden, valor de la orden y mes
SELECT
    CONCAT(empPerson.FirstName, ' ', empPerson.LastName) AS EmployeeName,
    ro.SalesOrderID,
    ro.OrderValue,
    ro.OrderMonth
FROM
    (SELECT
        SalesPersonID,
        SalesOrderID,
        OrderValue,
        OrderMonth,
        @rank := IF(@currentEmployee = SalesPersonID AND @currentMonth = OrderMonth, @rank + 1, 1) AS Rank,
        @currentEmployee := SalesPersonID,
        @currentMonth := OrderMonth
    FROM
        @orderValues
    ORDER BY
        SalesPersonID, OrderMonth, OrderValue DESC) AS ro
JOIN
    humanresources_employee emp ON ro.SalesPersonID = emp.BusinessEntityID
JOIN
    person_person empPerson ON emp.ContactID = empPerson.BusinessEntityID
WHERE
    ro.Rank <= 2 -- Los dos pedidos más altos
ORDER BY
    empPerson.FirstName, empPerson.LastName, ro.OrderMonth, ro.OrderValue DESC;





