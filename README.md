# Azure Data Administrator Course (DP-300)
- We will manage on-prem and cloud relational databases
- ![alt text](image.png)
- Basic SQL Queries can be identified as 
```sql
SELECT CountryRegion,Count(*) 
FROM SalesLT.Address
Where ModifiedDate < '2010-01-01'
Group by CountryRegion
Having Count(*) > 100
order by CountryRegion DESC

select * from SalesLT.SalesOrderDetail
select * from SalesLT.SalesOrderHeader

select SoH.SalesOrderID, OrderDate, OrderQty
from SalesLT.SalesOrderDetail SoD
JOIN SalesLT.SalesOrderHeader SoH
ON SoD.SalesOrderID = SoH.SalesOrderID

```

### Optimizing Query Performance
- Understanding Execution Plans
- There are 3 different types of execution plans
- First is an estimator plan: Here computer takes a look at the query angles
- ![alt text](image-1.png)
- Actual Execution Plan
- ![alt text](image-2.png)
- To view the execution plan use these queries
```sql

SET SHOWPLAN_ALL ON
GO

```
- ![alt text](image-3.png)
- We can see live query statistics also
- ![alt text](image-4.png)
- So the 3 types of execution plans are estimated execution plan, actual execution plan and live query statistics

### Different Types of loops used in execution plans and Scan and Seek
- We have 2 kinds of indexes
- Clustered and Non Clustered
- A clustered index would mean that the table would get reshaped for that particular index. All the roles would be sorted in that order.
- Non-clustered index is just maintained separately.
```sql
CREATE NONCLUSTERED INDEX [IX_Address_City] ON [SalesLT].[Address]
(
[CITY] ASC
)
GO
```
- ![alt text](image-5.png)
- Now when we run the estimated execution plan, we can see now we do an Index Seek over the IX_Address_City that we just created
- Also, **Nested Loop joins** are very efficient. They are used when we have 2 inputs: Input One and Input Two
- Input One is generally small
- Input Two is potentially large
- Advantages of nested loops, it uses the least I/O, that's input/output, and the fewest comparisons.
- Next is a **Merge Join**. This is useful when Input One and Input Two are not small
- It also requires Input One and Input Two to be sorted on their joins
- Merge Joins are very fast
- What happens if Index is not there?
- ![alt text](image-6.png)
- In this case there are no indexes on SalesOrderHeaderCopy and SalesOrderDetailCopy
- So as we can see in the execution plan, we use a **Hash Match JOIN**
- This is the least preferred join. It is used for large unsorted, unindexed inputs
- So we have 3 main types of JOINS: Nested Loop, Merge and Hash Joins in that order

#### Seek and Scan
- Scan is like going through a book from page 1 onwards.
- Seek is like going to an index at the back of the book
- In Sql Server 2017 onwards, we have a new batch mode adaptive join introduced
- It converts into a hash join or nested loop join once first input has been scanned.

#### All of this helps us to identify problem areas in Execution Plans

### Identifying Problem Areas in Execution Plans
```sql
SELECT * FROM SalesLT.Address
where City = 'Bothell'
```
- Do we need all the columns?
- Instead of Index Scan we should use Index Seek
- SELECT * uses a clustered index scan
- ![alt text](image-7.png)
- Since we now have an index on Modified Date and City
- It should do a Index seek right?
- But no, it still does a scan
- We can make it do an Index Seek by introducing a Where Statement
- ![alt text](image-8.png)
- ![alt text](image-9.png)
- ![alt text](image-11.png)
- The RECOMPILE keyword in SQL Server, when used with stored procedures, instructs the SQL Server query optimizer to discard the existing execution plan for the stored procedure and generate a new one the next time the procedure is executed. This can be useful in specific scenarios where the cached execution plan may not be optimal due to changes in data, schema, or query parameters.
```sql
CREATE PROCEDURE dbo.MyStoredProcedure
    @Parameter1 INT
WITH RECOMPILE
AS
BEGIN
    SELECT * FROM MyTable WHERE Column1 = @Parameter1;
END
```
- In this case, SQL Server will not cache the execution plan, and a fresh plan is created for each execution.
- You can use the RECOMPILE option when executing a stored procedure to generate a new execution plan for that specific execution only, without affecting the cached plan for future executions.
```sql
EXEC dbo.MyStoredProcedure @Parameter1 = 123 WITH RECOMPILE;
```
- In SQL Server, SARGable predicates (Search Argument-able predicates) are conditions in a query's WHERE clause or JOIN criteria that can effectively utilize indexes to optimize query performance.
- The term "SARGable" refers to predicates that allow the SQL Server query optimizer to perform an index seek or range scan rather than a full table scan or index scan, resulting in faster query execution.
- A predicate is SARGable if it can be directly matched to an index key, enabling the database engine to narrow down the rows to be processed efficiently. Conversely, non-SARGable predicates often force SQL Server to scan more data, degrading performance.
- Your choice of "LIKE" is correct because when used with a wildcard at the end (e.g., "HI%"), it allows the database to efficiently use indexes, making the query SARGable and faster.

## Evaluate Performance Improvements

### Identifying and Implementing Index Changes for Queries
- Indexes allow us to not go through the entire table and seek a particular point
- Requirement for an index: BIG Table
- We should use columns for indexes which are usually in the 'WHERE' clause
- Also the columns should be SARGable like less than, greater than or LIKE 'HI%'
  ```sql
    CREATE CLUSTERED INDEX ix_Address_AddressLine1_AddressLine2 //index name
    ON [SalesLT].[Address](AddressLine1, AddressLine2) //index columns

  ```
- We can have only one clustered index per table
- This is usually the primary key
- When we create a primary key, we also create automatically, a clustered index.
- It re-sorts the table based on the index.
- So a heap is a table without a clustered index,once we have a clustered index, it gets re-sorted based on the index.
- Most of the time clustered indexes are unique, but we can create a non-unique clustered index as well.
- It is quite good for identity columns
- We can have only 1 clustered index per table because we cannot sort a table two different ways at the same time.
- But we can have as many number of non-clustered indexes as we want.
- It creates a separate index.
- If we insert, update, delete rows, then all indexes need to be adjusted.
- So too many indexes slow down our machine.
- We dont have to index the entire table.
- Filtered Indexes use the WHERE clause
- n SQL Server, a **filtered index** is a non-clustered index that includes only a subset of rows from a table, based on a defined filter predicate (a WHERE clause). Unlike a standard index that covers all rows in a table, a filtered index is optimized for queries that target a specific portion of the data, making it smaller, more efficient, and faster for certain operations. Filtered indexes are particularly useful for improving query performance, reducing storage, and minimizing maintenance overhead in scenarios where only a subset of data is frequently queried.
- In SQL Server, the **fill factor** is a setting that determines how full the leaf-level pages of an index (clustered or non-clustered) should be when the index is created or rebuilt. It is expressed as a percentage (0 to 100) and controls the amount of free space left on each leaf page to accommodate future data modifications, such as inserts or updates. Properly configuring the fill factor can optimize performance by balancing storage efficiency, index maintenance, and query performance.
- A fill factor of 100 means pages are filled completely, leaving no free space (maximizing storage but potentially increasing page splits).
- A fill factor of 70 means pages are filled to 70%, leaving 30% free space for future inserts or updates.
- A fill factor of 0 is equivalent to 100 for leaf pages but leaves minimal space in intermediate levels (rarely used).
- ![alt text](image-12.png)
- We cant create indexes manually in Azure SQL Database
- Traditionally we store data inside a row store.
- In Sql server 2012, we got the column store.
- Column store stores each column separately and we combine them at the end
- This is useful in huge amount of database like Data Warehouse.
- Column Store storage compresses the data down.
- Column store is not the standard type of index.
- Column store indexes are available in most tiers of Azure SQL Database
- If we dont need an Index, we can always drop it.


### Use DMVs to improve query performance execution
- We will figure out how we can use Dynamic Management Views(DMVs) to gather query performance information
- ![alt text](image-13.png)
- DMVs are system views

### sys.dm_exec_cached_plans
- This can retrieve last execution plans in the cache
- ![alt text](image-14.png)
- ![alt text](image-15.png)
- It can show which queries is running the longest
- Whether we can improve the query by using indexes
- It can also answer questions like: Which used the most cumulative CPU
- DMV stands for Dynamic Management View. DMVs, along with Dynamic Management Functions (DMFs), are powerful tools introduced in SQL Server 2005 to provide insights into the internal state, performance, and health of a SQL Server instance. They are collectively referred to as Dynamic Management Objects (DMOs) and reside in the sys schema with names starting with dm_.
- DMVs and DMFs return server state information that database administrators (DBAs) and developers use to:
- Monitor Server Health
- Track resource usage (CPU, memory, disk I/O).
- Monitor active sessions, connections, and requests.
- Analyze wait types to identify bottlenecks.
- Identify slow or resource-intensive queries using DMVs like sys.dm_exec_query_stats.
- Detect blocking, deadlocks, or contention issues (e.g., sys.dm_tran_locks, sys.dm_os_waiting_tasks).
- Analyze query execution plans and optimize them.
- Identify unused or missing indexes (sys.dm_db_index_usage_stats, sys.dm_db_missing_index_details).
- In Azure SQL Database, DMVs like sys.dm_db_resource_stats help monitor resource usage, and sys.dm_continuous_copy_status tracks replication lag.
- DMVs provide real-time or near-real-time snapshots of SQL Server's internal state, unlike static catalog views that show metadata.
- ![alt text](image-16.png)
- ![alt text](image-17.png)


### How to decide which DMV to get the appropriate information
- ![alt text](image-18.png)
- ![alt text](image-19.png)
- ![alt text](image-20.png)
- Get current session ID
```sql
select @@spid
```
- ![alt text](image-21.png)
- ![alt text](image-22.png)
- ![alt text](image-23.png)
- ![alt text](image-24.png)

### Recommend Query construct modifications based on resource usage
- ![alt text](image-25.png)
- Remember SalesHeaderCopy and SalesDetailCopy donot have any indexes
- SQL Server is not complaining about indexes not being there because there are only 32 rows in our database
- What if we had lot more rows?
- If we insert lot many rows and run the query and look at the execution plan we get this:
- ![alt text](image-26.png)
- It is asking us to create a non-clustered index.
- It gives us the recommended query to use:
- ![alt text](image-27.png)
- Now lets just run the query again after creating the index
- ![alt text](image-28.png)
- Now we have an index scan
- This is one way of detecting missing indexes
- Can we do it for the entire database? i.e detect missing indexes
- Answer is YES, we need to use a DMV
```sql
select * from sys.dm_db_missing_index_details
```
- ![alt text](image-29.png)
- ![alt text](image-30.png)
- Biggest query construct modification we can think of is to create indexes whenever they are needed
- But dont create too many indexes, it slows the system if we are doing lot of INSERT/UPDATE/DELETEs as all indexes need to be updated
- We also need to use columns that are SARGable
- So we should not use functions when we can avoid it


### Assess the use of hints for query performance
- ![alt text](image-31.png)
- Suppose, in the execution plan we see that we used a HASH MATCH. We probably want to use a MERGE JOIN.
- When we write the query, we can instruct SQL Server to use that, by using query hints using OPTION keyword
- ![alt text](image-32.png)
- ![alt text](image-33.png)
- But Microsoft recommends using Query Hints as a last resort.
- We can have LOOP joins also
- ![alt text](image-34.png)
- We dont need to use it unless we have to.
- We can have multiple OPTIONs separated by a comma
- We can optimize stored procs like this
- ![alt text](image-35.png)
- Optimize for unknown is quite useful if you want the stored procedure to just optimize for a particular parameter with unknown value.
- ![alt text](image-36.png)
- Most often SQL Server Query optimizer does a good job


## Plan and Implement Data Platform Resources

### Deploy Database Offerings on Selected Platforms
- ![alt text](image-37.png)
- ![alt text](image-38.png)
- A managed instance is like having a fuller version of SQL Server on a cloud with a SQL Server that you can actually manipulate, though we cannot manipulate the Windows machine behind it.
- ![alt text](image-39.png)
- We can also get SQL Virtual Machine with a Windows Server + SQL Server installed on it.
- In the Marketplace, we can also deploy SQL Server on different Operating Systems
- ![alt text](image-40.png)
- ![alt text](image-41.png)

### Configuring Customized Deployment Templates
- For any SQL Server, we can go and Export Template as ARM Template
- ![alt text](image-42.png)
- If we create any resource, we generate it through an ARM Template.
- Remember "Download a template for automation"
- This allows us to build infrastructure as a code (IaC)
- For a resource group also we can export a template
- This way we can not only export a SQL Database but SQL Server also
- We can then deploy a custom template
- ![alt text](image-43.png)
- We can also deploy through Azure Powershell
- ![alt text](image-44.png)
- ![alt text](image-45.png)
- ![alt text](image-46.png)
- We can also use Azure Pipelines
- We can use DACPAC( Data Tier Application - Portable Artefact )
- We will add this DACPAC to Azure-pipelines.yml
- We can also deploy databases using SQL Scripts
- If we have to create 100 databases, we can use ARM Templates
- For automated deployments, we can use Powershell, CLI, DACPAC in Azure Pipelines or if we have an existing template
- Usually, we export templates, make some adjustments and deploy a new database.

### Evaluate Requirements and functional benefits/impact for deployment
 - ![alt text](image-47.png)
 - We can use SQL Agents in a Managed Instance and not on a SQL Database
 - T-SQL Syntax is not available in Azure Sql Database
 - Similarly trace flags are not supported in Azure SQL Database
 - Trace Flags are things which we startup in a server, since there is no server to startup, we dont have any control.
 - However, in Managed Instance, there are some trace flags that are supported
 - All trace flags are supported in virtual machines.
 - But in SQL Server VM, we have to manage backups and patches.
 - We dont have to do it in Managed Instance or SQL Database
 - ![alt text](image-48.png)
 - In Managed Instance, we can use CLR

### Evaluate Security and Scalability Aspects
- ![alt text](image-49.png)
- ![alt text](image-50.png)

### High Availability/Disaster Recovery of Possible Database Offerings
- ![alt text](image-51.png)
- ![alt text](image-52.png)
- ![alt text](image-53.png)
- ![alt text](image-54.png)

### Automate Deployment by using ARM Templates
- ARM Template is a JSON
- Go to Deploy a custom template
- ![alt text](image-55.png)
- ![alt text](image-56.png)
- ![alt text](image-57.png)
- We can build our template in the editor
- We even have Quickstart templates
- ![alt text](image-58.png)
- ![alt text](image-59.png)
- ![alt text](image-60.png)
- ![alt text](image-61.png)
- ![alt text](image-62.png)
- ![alt text](image-64.png)
- We need to remember the types here for the resources: we have one type for the server and another for the database
- Notice the "dependsOn" field which is similar to dependsOn field in docker-compose
- This basically tells us that the database should be deployed only after server has been deployed
- ![alt text](image-65.png)
- ![alt text](image-66.png)
- ![alt text](image-67.png)
- Now it will create the server and database

### Automated Deployment by using Azure Bicep
- JSON requires lot of code to understand and it is unwieldy
- ![alt text](image-68.png)
- So thats why Bicep was invented
- ![alt text](image-69.png)
- Bicep is similar to C#
- We can deploy using Bicep only by using Azure Pipelines or Github Actions or VS Code
```bicep
@description('Specifies the location of the resource')
param location string = 'eastus'

resource sqlServer 'Microsoft.Sql/servers@2014-04-01' ={
  name: uniqueString('sqlserver', resourceGroup().id)
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'P@ssword123'
}
}

resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2014-04-01' = {
  parent: sqlServer
  name: 'AutomateBicep'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: 'Basic'
  }
}

```
- We also have Bicep Playground which converts Azure Bicep into ARM Templates
- ![alt text](image-70.png)
- ![alt text](image-87.png)
- ![alt text](image-71.png)
- It will ask for signin, our subscription and then we can deploy it
- ![alt text](image-72.png)
- ![alt text](image-73.png)
- ![alt text](image-74.png)
- Bicep is basically shorthand for ARM Templates, end of the day it is converted into ARM Template only.
- We can deploy it using Azure Pipelines, Github Actions, Azure CLI 

### Automate Deployment by using Powershell
- We first create a resource group
- ![alt text](image-75.png)
- Next we will create database server
- ![alt text](image-77.png)
- ![alt text](image-78.png)
- ![alt text](image-79.png)
- ![alt text](image-80.png)
- ![alt text](image-81.png)

### Automate Deployment using Azure CLI
- First create a resource group
- ![alt text](image-82.png)
- ![alt text](image-83.png)
- ![alt text](image-84.png)
- ![alt text](image-85.png)
- ![alt text](image-86.png)

### Configure Azure SQL Database resources for scale and performance
- We can create the following SQL databases:
- ![alt text](image-88.png)
- Resource Group is just a container where all the resources for our project are
- ![alt text](image-89.png)
- 6 different tiers we can have
- ![alt text](image-90.png)
- In vCore based, we can specify the vCores and we can specify the speed and amount of storage. We can have 2-80 vCores.
- Cost goes up and down based on the number of vCores we have selected
- We also have a database maximum size
- ![alt text](image-91.png)
- The maximum size is partly dependent on the vCores. 
- It is also dependent on the hardware configuration. Standard Configuration nowadays is Gen5
- Amount of Log Space allocated is directly proportional to amount of data maximum size. It is approximately 30% of the data max size. 
- We also have difference in IOPS. That's input-output operations per second.
I-O-P-S, the concurrent workers number of requests that you can have and the backup retention as well.
- If we want more, we can go from General Purpose to Hyperscale, here we can go upto 100 terabytes and max number of vCores is 80
- Business Critical is when we need high transaction rate and high resiliency. 
- Cost also increases proportionally.
- Go for Hyperscale, when we need storage more than 4 Terabytes
- For business critical compute model, the IO latency is highly reduced.

### DTU based purchasing model, Server vs Serverless
- DTU: Database Transaction Units
- They are packages or bundles of maximum number of compute, memory and input/output or read and write resources for each class.
- ![alt text](image-92.png)
- ![alt text](image-93.png)
- ![alt text](image-94.png)
- Remember that Change Data Capture(CDC) cannot be used if we have less than 1 vCore.
- So, we cannot use it in S0,S1,S2 DTUs
- For more I/O intensive workloads, go for Premium DTU models
- ![alt text](image-95.png)
- If we want to calculate how many DTUs we may need, there is a website:
- http://dtucalculator.azurewebsites.net
- We will have to run a few traces on our existing on-prem database and then it will give us a figure recommendation
- If we have DMV(Dynamic Management Views) for them to have accurate figures, we may need to flush our query store before we rescale and to do that we need to issue the command 
- ![alt text](image-96.png)
- ![alt text](image-97.png)

### Serverless/Provisioned and Elastic Pools
- ![alt text](image-98.png)
- In Serverless, we are billed by the second
- After 1 hour of inactivity the database activity is stopped.
- ![alt text](image-99.png)
- In Provisioned, we have option to save money. If we have an existing SQL Server license, we can save on costs here.
- ![alt text](image-100.png)
- **Azure SQL Database Elastic Pools** are a cost-effective and efficient solution for managing and scaling multiple databases with varying and unpredictable usage demands. They allow multiple databases to share a common set of resources (such as CPU, memory, and storage) on a single Azure SQL server, optimizing resource utilization and simplifying management.
- Elastic pools allocate a fixed set of resources, measured in either eDTUs (elastic Database Transaction Units) or vCores (virtual cores), depending on the purchasing model. **These resources are shared among all databases in the pool.**
- Databases can dynamically use more or less resources based on their workload, within configurable minimum and maximum limits, ensuring flexibility and performance elasticity.
- Instead of provisioning resources for each database individually, which can lead to over-provisioning or under-provisioning, elastic pools allow you to pay for a single pool's resources. This reduces costs, especially when databases have "spiky" or unpredictable usage patterns. For example, Microsoft notes that consolidating 20 databases into a 100 eDTU pool can use 20 times fewer DTUs and cut costs by up to 13 times compared to individual provisioning.
- Elastic pools are available in Basic, Standard, Premium, and Hyperscale tiers, each offering different performance and capacity levels. The tier determines the features and resource limits available to databases in the pool.
- ![alt text](image-101.png)
- ![alt text](image-102.png)
- In Elastic Pools, we cannot use Hyperscale option
- ![alt text](image-103.png)
- Unit price for eDTUs is an extra 50%

### Other Azure SQL Configuration Settings
- ![alt text](image-104.png)
- ![alt text](image-105.png)
- ![alt text](image-106.png)
- We can directly connect to Azure Sql Database or Azure SQL Database Gateway
- ![alt text](image-107.png)
- We can setup Azure Defender for SQL 
- ![alt text](image-108.png)
- ![alt text](image-109.png)
- **Database collation** refers to a set of rules that define how data in a database is sorted, compared, and stored, particularly for character-based data such as strings.
- Collation determines:
- Case sensitivity: Whether uppercase and lowercase letters are treated as equal (e.g., 'A' vs. 'a').
- Accent sensitivity: Whether accented characters are distinct from their non-accented counterparts (e.g., 'é' vs. 'e').
- Sort order: How strings are ordered (e.g., alphabetical order, ignoring case, or respecting diacritics).
- Character encoding: How characters are represented in the database, ensuring proper storage and retrieval.
- In databases like Azure SQL Database, collation is set at the database level (default for all string columns) or at the column level (for specific columns). It applies to data types like CHAR, VARCHAR, NCHAR, and NVARCHAR.
- Collations are particularly important for:
- Ensuring consistent sorting and comparison in queries.
- Supporting multilingual applications where different languages have unique sorting rules.
- Handling case or accent sensitivity in searches or comparisons.
- A collation name typically includes:
- Language or locale: E.g., Latin1_General (Western European languages), SQL_Latin1_General_CP1 (SQL Server-specific).
- Code page: Defines the character encoding (e.g., CP1 for Code Page 1252).
- ![alt text](image-110.png)
- For example:
- Latin1_General_CI_AS: Case-insensitive, accent-sensitive, used for Western European languages.
- SQL_Latin1_General_CP1_CS_AS: Case-sensitive, accent-sensitive, SQL Server-specific.

### Calculate Resource Requirements including Elastic Pool Requirements
- There are 2 kinds of purchasing model: vCore based model and DTU based model
- ![alt text](image-111.png)
- DTU is bundle of compute, storage and IO resources
- vCore based model is transparent and is more flexible
- In DTU based model, it is very difficult to figure out how many DTUs we need
- We should also take a look at avg DTU utilization * number of databases
- Also take a look at the concurrently peaking databases multiplied by the peak DTU utilization per database
- Do our databases peak at the same time? If yes, pool is not recommended for us.
- If they peak at different times, think whether we can use level it out better using an elastic pool 
- But remember eDTU for elastic pools are more expensive than regular DTUs
- Also we cannot have elastic pools with the hyperscale model
- ![alt text](image-112.png)
- ![alt text](image-113.png)
- ![alt text](image-114.png)

### Database Sharding and Table Partitioning
- ![alt text](image-115.png)
- Maximum database capacity can easily be exceeded in a database
- What if our computing resources are exceeded?
- We can have horizontal scaling and horizontal scaling
- ![alt text](image-116.png)
- We can divide our table
- ![alt text](image-117.png)
- Backups for a particular partition are easier to do than the whole database
- What if data from 2015 fails, we wont be able to access it but we should be able to access data from other partition
- This is called **Sharding**
- For sharding we could have a lookup strategy. 
- We could have a table which has a shard key and a map which shows where they are stored. 
- This offers as much control as we need
- We could shard by month, year etc.
- It does have some additional overhead.
- What if we are in a seasonal industry
- Data for June is more than Data for July
- We could follow a hash strategy also where there is some random element for distribution and somehow ensure even distribution among the shards
- Rebalancing shards is difficult
- Getting sequential data might be tougher
- We can also have range strategy as described earlier
- We can also have filegroups
- Filegroups cant be used in Azure SQL Database
- In Filegroups we add additional files or data files and put them into filegroups and create a partition function.
- ![alt text](image-118.png)
- So if we have a Sales Order Detail ID, if the value is one or less, it goes into first file, if it is 100 or less, it goes in the second file, etc
- Partition Function is what goes and Partition Scheme is where it goes
- This is called a table partition
- We can also split the table up
- ![alt text](image-119.png)
- Each partition is a subset of the columns
- Not the best strategy
- We also need a way to join all the partitions
- ![alt text](image-120.png)
- We can have different tables in different databases
- In Vertical partitioning, we can scale vertically to add more compute power
- We should keep data geographically close to the user
- We should also consider archiving the data
- This means we keep the data offline and rehydrate it only when we need.

### Evaluate the use of compression for tables and indexes
- We compress so that we get reduced space
- It is useful for data which is infrequently used.
- 3 main types of compression: None, Row compression, Page compression
- Suppose we have a char(60) as opposed to a varchar
- So char 60 contains 60 spaces of data.
- So char and nchar will be compressed and we can get savings upto 50% in English/German and just 15% in case of Japanese
- So, it depends on what our language is
- Certain types of dates like datetime can be compressed.
- Row compression looks at what it can compress for each of the individual items
- Most of the compression related savings come from char and nchar.
- We also have **Page Compression**
- Page compression in Azure SQL Database is a data compression technique that reduces the storage footprint of database objects like tables and indexes, optimizing disk space and potentially improving query performance. It builds on row compression and includes additional strategies to minimize data redundancy within a page.
- Consists of 3 operations: 
- Row Compression: Optimizes individual rows by using variable-length storage for fixed-length data types (e.g., storing a CHAR(100) as a VARCHAR), eliminating storage for NULL or zero values, and reducing metadata overhead.
- Prefix Compression: Identifies common prefix patterns within each column on a page and stores them once in the compression information (CI) structure, just after the page header. Repeated prefixes in the column are replaced with references to this stored prefix, reducing redundancy. For example, if multiple rows in a column start with "abc", the prefix "abc" is stored once, and rows reference it with pointers or partial matches.
- ![alt text](image-121.png)
- Dictionary Compression: Searches for repeated values or patterns across the entire page (not just within a single column) and stores them in the CI structure. These repeated values are replaced with references, further reducing storage needs. For instance, a value like "xyz" appearing in multiple columns or rows on the page is stored once and referenced.
- When page compression is enabled, the SQL Server Database Engine evaluates each page during a rebuild operation. It applies row compression first, followed by prefix compression, and finally dictionary compression.
- Compressed data is stored on disk in fewer pages, reducing the physical size of the database. The compression is transparent to applications, as the Database Engine handles compression and decompression automatically.
- The CI(Compression Information) structure stores prefix and dictionary entries, which are used to reconstruct the original data during queries.
- Fewer pages mean fewer disk I/O operations, which can speed up query execution, particularly for I/O-intensive workloads like table scans or large joins
- In Azure SQL Database, smaller database sizes can lower storage costs, especially in environments with large datasets.
- Page compression is ideal for tables or indexes with high scan operations (e.g., data warehouse queries), as it reduces the number of pages read from disk.
- Compression and decompression require additional CPU resources, which can increase query execution time for write-heavy workloads (inserts, updates, deletes).
- This trade-off is less significant for read-heavy workloads, where I/O savings often outweigh CPU costs.
- Compression is available in Azure SQL Database and Azure SQL Managed Instance 
- Also for SQL Server on VM, it is available from SQL Server 2016 Service Pack 1 in all editions
- Before that it was only available in Enterprise Edition

#### What can we compress?
- We can compress tables
- Tables either stored without a clustered index or with it
- Tables without a clustered index are called heaps
- If a table has a column with less data then compression is not of much use.
- We can also compress indexes like a non clustered index
- We can also compress an indexed view.
- If we have a table with lot of partitions, then different partitions can be compressed using different settings.
- ![alt text](image-122.png)
- ![alt text](image-123.png)
- ![alt text](image-124.png)
- ![alt text](image-125.png)
```sql
USE [dbbackup]
ALTER TABLE [SalesLT].[SalesOrderDetail] REBUILD PARTITION = ALL
WITH
(DATA_COMPRESSION = PAGE
)


```
- Similar queries can be written for an index
- ![alt text](image-126.png)
- We can also estimate data compression savings
- ![alt text](image-127.png)
- We also have columnstore tables
- Columnstore table concentrates on individual columns and mashes them together whenever needed.
- Columnstore tables are used in data warehouses.
- Good thing about columnstore objects is that they are always compressed.
- They can be compressed further from columnstore compression by using columnstore archival compression. It saves even more space.
- However, this kind of compression is best when data is not often read but we want the data to be retained for regulatory or business reasons. Also it does save space, but there is a very high compute cost in uncompressing it.
- For Rowstore tables or our regular standard tables, we can choose from page, row or None compression
- Page compression further consists of Row, Prefix and Dictionary compression.

### Setup SQL Data Sync
- We can have 2 databases which are Azure SQL databases and another one which is on-prem SQL Database
- We can use **Azure SQL Data Sync** to synchronize data across multiple databases
- For this our tables need to have a primary key and we cant change the primary key.
- It doesnot work with Azure SQL Managed Instances
- We define one of the Azure SQL Databases as the Hub database and others are member databases
- If any change is made in any databases, it is replicated in all other databases
- ![alt text](image-128.png)
- We will need some kind of conflict resolution
- We also need a database which will keep track of everything
- We can call it Sync Metadata Database or Sync Hub
- ![alt text](image-129.png)
- It should be an empty database
- For member databases we need a Sync Agent
- ![alt text](image-130.png)
- ![alt text](image-131.png)
- Install the sync agent on on-prem databases
- ![alt text](image-132.png)
- ![alt text](image-133.png)
- ![alt text](image-134.png)
- ![alt text](image-135.png)
- ![alt text](image-136.png)
- ![alt text](image-137.png)
- ![alt text](image-138.png)
- Open the On prem database data sync agent
- ![alt text](image-139.png)
- ![alt text](image-140.png)
- ![alt text](image-141.png)
- ![alt text](image-142.png)

## Evaluate a strategy for Migrating to Azure
- ![alt text](image-143.png)
- We need to consider if we need to allow downtime in migration
- ![alt text](image-144.png)

### Azure Migrate
- ![alt text](image-145.png)
- ![alt text](image-146.png)
- ![alt text](image-147.png)
- ![alt text](image-148.png)
- ![alt text](image-149.png)
- We have Azure Databox which helps send large amounts of data to Azure
- ![alt text](image-150.png)
- ![alt text](image-151.png)

### SQL Server Migration Assistant
- ![alt text](image-152.png)
- ![alt text](image-153.png)
- ![alt text](image-154.png)
- ![alt text](image-155.png)
- ![alt text](image-156.png)
- ![alt text](image-157.png)
- ![alt text](image-158.png)
- ![alt text](image-159.png)
- ![alt text](image-160.png)
- ![alt text](image-161.png)

### Data Migration Assistant
- It helps us to upgrade to a modern data platform by detecting compatibility issues that can impact database functionality in our version of SQL Server or Azure SQL Database. DMA recommends performance and reliability improvements for our target environment and allows us to move schema and uncontained objects from source server to target server.
- **For larger migrations, we should use Azure Database Migration Service which can migrate databases at scale.**
- ![alt text](image-162.png)
- ![alt text](image-163.png)
- ![alt text](image-164.png)
- ![alt text](image-165.png)
- ![alt text](image-166.png)
- ![alt text](image-167.png)
- ![alt text](image-168.png)
- ![alt text](image-169.png)
- ![alt text](image-170.png)
- ![alt text](image-171.png)
- ![alt text](image-172.png)
- ![alt text](image-174.png)
- ![alt text](image-173.png)
- ![alt text](image-175.png)
- ![alt text](image-176.png)
- ![alt text](image-177.png)
- ![alt text](image-178.png)
- ![alt text](image-179.png)
- ![alt text](image-180.png)

### Azure Database Migration Service
- The Azure Database Migration Service (DMS) is a fully managed service provided by Microsoft Azure to facilitate seamless migrations of databases from various sources to Azure data platforms with minimal downtime.
- It supports both operational database and data warehouse migrations, enabling organizations to modernize their data infrastructure by moving on-premises or cloud-based databases to Azure.
- Azure DMS is designed to simplify, guide, and automate database migrations to Azure, supporting a variety of database engines and migration scenarios. It provides a unified platform to assess, plan, and execute migrations, ensuring reliability, performance, and minimal disruption to business operations. The service integrates with other Azure tools, such as Azure Migrate and Azure Data Studio, to offer a comprehensive migration experience.
- DMS enables organizations to move data, schemas, and database objects from on-premises environments, other clouds, or legacy systems to Azure’s managed database services, such as Azure SQL Database, Azure SQL Managed Instance, Azure Database for MySQL, PostgreSQL, and others.
- Supports both offline (one-time migration with downtime) and online (continuous replication with minimal downtime) migration modes.
- Supports a variety of database engines, including SQL Server, MySQL, PostgreSQL, Oracle, and MongoDB.
- ![alt text](image-181.png)
- ![alt text](image-182.png)
- ![alt text](image-183.png)
- ![alt text](image-184.png)
- Premium supports both online and offline migration
- ![alt text](image-185.png)
- ![alt text](image-186.png)
- ![alt text](image-187.png)
- ![alt text](image-188.png)
- ![alt text](image-189.png)
- ![alt text](image-190.png)
- There are other migration strategies also like BCP which is Bulk Copy Program that can be used for connecting from an on-prem or SQL Server on a Virtual Machine to Azure SQL.
- We could use the BULK INSERT Command so that we can log data from Azure Blob Storage
- We could use SSIS, that could be used for ETL
- We can also use Spark or Azure Data Factory
- For online migration strategy, use the premium pricing tier and allows continuous online migration or we could use Offline Migration for greater speed.

### Implement a Migration between Azure SQL Services
- If we are migrating from Azure SQL or Azure Managed Instance, we can open SQL Import and Export Wizard
- This wizard uses SQL Server Integration Services or SSIS.
- ![alt text](image-191.png)
- ![alt text](image-192.png)
- ![alt text](image-193.png)
- ![alt text](image-194.png)
- ![alt text](image-195.png)
- SQL Server Integration Services (SSIS) is a Microsoft tool used to extract, transform, and load (ETL) data between different systems. It simplifies moving and processing data for tasks like data integration, migration, and automation.
- Extract Data: Pulls data from various sources, such as databases (e.g., SQL Server, Oracle), Excel files, CSV files, or APIs.
- Transform Data: Cleans, modifies, or reformats data to meet the needs of the destination system. Examples include filtering rows, converting data types, aggregating values, or joining datasets.
- Load Data: Transfers the transformed data into a target system, such as a database, data warehouse, or another file format.
- Data Migration: Move data from legacy systems to modern databases, like migrating to Azure SQL Database.
- Data Warehousing: Load data into data warehouses (e.g., Azure Synapse Analytics) for reporting and analytics.
- Data Integration: Combine data from multiple sources (e.g., merging sales data from CRM and ERP systems).
- Automation: Schedule and automate repetitive data tasks, like daily data imports or backups.
- Data Cleansing: Standardize and clean data to ensure accuracy (e.g., removing duplicates or fixing formats).
- ![alt text](image-196.png)
- This export data can copy data but cannot be used to copy Views, Stored Procedures or Functions
- However it is quick and easy to do
- To overcome there drawbacks, we use **data tier applications** or BACPAC
- So now we export Data Tier Application, It allows us to export not just the data but also the schema
- ![alt text](image-197.png)
- ![alt text](image-198.png)
- ![alt text](image-199.png)
- We can import these BACPAC files also
- ![alt text](image-200.png)
- ![alt text](image-201.png)
- ![alt text](image-202.png)
- It imports data, views and stored procedures
- Much better way of exporting and importing data
- ![alt text](image-203.png)
- ![alt text](image-204.png)
- ![alt text](image-205.png)
- Another way of importing and exporting data is through SQL packages
- ![alt text](image-206.png)
- ![alt text](image-207.png)
- ![alt text](image-208.png)
- We can also use Azure Powershell or Azure CLI
- New-AzSqlDatabaseImport
- az sql db import
- Import Database in Azure Portal doesnot exist for Azure Managed Instance

### Performing Post Migration Validations
- We should have some tests
- We should use SQL queries against both source and target databases which should give similar results in the same timeframe. This will allow us to check if the indexes have been migrated or not
- For an on-prem database, we have something called compatibility level like 100,120,150,160,170
- If we are going from SQL Server 2012 to Sql Server 2014
- On Sql Server on Azure VM, we can choose compatibility level.
- So we may need confirm if the existing queries under the new compatibility level using the best plan?
- Is the performance worse?
- We can force the last known good plan using Auto-tuning.
- Do the stored procedures need to be recompiled?
- Always check for missing indexes
- Check for missing features or are there any new features in the new database that can used to our advantage.
- ![alt text](image-209.png)