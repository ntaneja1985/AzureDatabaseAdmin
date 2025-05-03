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

## Configuring Database Authentication and Authorization

### Configure Microsoft Entra ID Authentication
- Authentication is who you are and Authorization is what can you do
- ![alt text](image-210.png)
- SQL Server Authentication is sent in plaintext and Azure Entra ID is more secure.
- Windows Server also has Windows Server Active Directory
- Azure Entra ID can synchronize with on prem Azure AD
- Azure Entra ID supports the following Authentication Methods:
- ![alt text](image-211.png)
- It supports FIDO Security Key which is hardware based
- Microsoft Authenticator we use on our Mobile Phone
- It supports Text Messaging also besides temporary access pass.
- There are 3 kinds of authentication:
- Cloud Only Identities
- Federated Authentication
- Pass-Through Authentication
- Federated Authentication is used if we want to integrate with an existing federation provider i.e another app with login to Azure Active Directory.
- In Cloud Only Identities where Azure AD handles sign-in completely in the cloud.
- For all else, use Pass-through authentication
- On an Azure VM, we can use passwordless authentication. 
- We can also use Managed Identities
- We can create a certificate and App can connect to Azure Data using that.
- In SSMS, we can use MFA
- For new users we can set this up
- ![alt text](image-212.png)

### Create Users from Microsoft Entra ID identities
- We can use this SQL Query
- ![alt text](image-213.png)
- ![alt text](image-214.png)
- ![alt text](image-215.png)
- ![alt text](image-216.png)
- In the SQL Server, go to Azure Entra ID and setup the Admin user before you can create other users
- ![alt text](image-217.png)
- ![alt text](image-218.png)
- ![alt text](image-219.png)
- Once successfully signed in, we can create users from external provider
- ![alt text](image-220.png)
- ![alt text](image-221.png)
- Now we can create users and login in through those users to the Azure SQL Database
- This concludes our authentication part
- **What is the difference between SQL Server Admin and Azure Entra ID Admin**
- ![alt text](image-222.png)
- Both of them can create users based on SQL Server authentication, both of them can create contained database users based on SQL Server authentication without logins.
- Only difference is Azure AD Admin can create users based on Active Directory users and groups

### Configure Security Principals - Roles
- In the above example, if we login as Azure Entra User, we cant see any tables
- ![alt text](image-223.png)
- We need to add the user to the Roles
- ![alt text](image-224.png)
- ![alt text](image-225.png)
- Now we get access to all the tables in the database
- We can remove role like this
- ![alt text](image-226.png)
- db_backupoperator is not valid for Azure SQL Database
- db_ddladmin can run data creation commands
- db_datareader can view all the data and the views but not insert any new rows
- db_datawriter can view and insert/update data in the rows in the tables
- db_denydatawriter means we cannot alter/change old data
- Similarly db_denydatareader means we cannot read old data
- What if we want to give access to one particular table
- In Azure SQL Database, we have 2 additional database roles
- These roles are not visible in the sql database but in the master database
- ![alt text](image-227.png)
- dbmanager : you can create or delete databases
- loginmanager: can create or delete logins in the master database
- To get all roles
- ![alt text](image-228.png)
- In Azure we also have RBAC
- ![alt text](image-229.png)
- Suppose we want access to one particular table but not all of them
- We can use GRANT/REVOKE/DENY Keywords
- ![alt text](image-230.png)
- ![alt text](image-231.png)
- ![alt text](image-232.png)
- To revoke permission on a particular table, use the REVOKE keyword
- ![alt text](image-233.png)
- DENY means definitely NOT
- ![alt text](image-234.png)
- DENY has higher privilege than GRANT
- ![alt text](image-235.png)
- ![alt text](image-236.png)
- To remove the DENY permission, use REVOKE keyword
- REVOKE means no permission
- ![alt text](image-237.png)
- REVOKE doesnot override Roles like datareader,dbwriter and so on
- But DENY overrides roles like datareader, dbwriter etc.

### Configure Security Principals - Individual Permissions
- If we have to generalize individual permissions we can do it like this
- ![alt text](image-238.png)
- However lets says a user JANE grants certain permissions to SUSAN, now we want SUSAN to delegate permissions to someone else, we then use **WITH GRANT OPTION**
- ![alt text](image-239.png)
- MAIN Permissions are SELECT, INSERT, UPDATE, DELETE
- We also have CONTROL, REFERENCES, TAKE OWNERSHIP, VIEW CHANGE TRACKING, VIEW DEFINITION permissions
- For Schemas we have ALTER Permission with CREATE,ALTER, DROP TABLE
- For stored procs/functions we have ALTER, EXECUTE, VIEW CHANGE TRACKING, VIEW DEFINITION
- What happens if we have EXEC permission on a stored procedure but we dont have permission to Select something from the table? Will the stored proc run?
- Answer is Yes
- ![alt text](image-240.png)
- When we go inside a stored procedure, we can read anything from the schema.
- This is called ownership chaining
- ![alt text](image-241.png)

### ALL Permission in Security Principals
- ALL Permission would be deprecated. It is maintained for backwards compatibility
- ALL Permission for tables and views means that you can delete, insert, references, select, and update.
- But we dont have Take ownership.
- For procedures, then ALL Permission means execute.
- For scalar functions then ALL permission means execute and references.
- And for table valued functions ALL permission means delete, insert, references, select and update.
- ALL Permission for Database allows you access to backup database, backup log, create database, create function, create procedure, create rule, create table, and create view.
- Doesnot give access to ALTER and DROP Database
- ![alt text](image-242.png)
- So ALL permission is a bit misleading
- We can create a stored procedure with EXECUTE AS permission of a certain user
- ![alt text](image-243.png)
- To get permissions for a particular user/database/object we can use 
- ![alt text](image-244.png)
- Remember DENY is higher than GRANT

### Configure Permissions by using Custom Roles
- It is not possible for us to keep granting, revoking permissions like this
- It is always better to package permissions together in a custom role.
- datareader,dbwriter are fixed database roles.
- Now we can create custom roles
- ![alt text](image-245.png)
- We will now add user to a custom role
- ![alt text](image-246.png)
- ![alt text](image-247.png)
- ![alt text](image-248.png)
- ![alt text](image-249.png)
- ![alt text](image-250.png)

### Apply Principal of Least Privilege for all securables
- Users should have the least privilege that is necessary for them to do their job.
The least privileged user account, LUA.
-  In other words, don't give people dbowner, when all they need is a single select grant, for instance. So have a think about the minimum that users need.
- You can use roles, custom roles, and also the fixed database roles.
- So you can assign permissions to the roles, and then assign users to the roles.
- This makes security administration much easier.
- DENY doesnot apply to Object Owners
- Dont put DENY in public roles
- Dont give direct rights to the underlying objects like tables, instead give access to Views
- Select Permission on a database would include all child schemas and all the tables and views.
- If we have select permission on a schema, it gives us select permission on all the tables and views
- If you give a select on a table, then that gives the select permission, on that one table only.
- Also please dont use ALL permission, use principle of least privilege.

## Implement Security for Data at Rest and Data in Transit
### Implement Transparent Data Encryption
- TDE encrypts and then it de-encrypts data at the page level at rest.
- So in other words, if you write data it's encrypted when written, and when you read data, it's decrypted.
- ![alt text](image-251.png)
- TDE uses a database encryption key
- ![alt text](image-252.png)
- ![alt text](image-253.png)
- TDE key is set at server level and the databases inherit it
- At database level, we can set TDE ON or OFF
- ![alt text](image-254.png)
- In SQL Managed Instance, we can set it using T-SQL statement
- ![alt text](image-255.png)
- We can even set it in Powershell
- ![alt text](image-256.png)
- We can also do it using REST API

### Implement Object-Level Encryption and Always Encrypted
- Let's say that you have got a table, which people need to have access to, but, it's also got sensitive data.
- We can encrypt it using Always Encrypted
- This is available in Azure SQL, Managed Instance and on VMs
- What about setting it on the table level?
- Lets say we have AddressLine1 and City as sensitive columns which we need to encrypt
- ![alt text](image-257.png)
- ![alt text](image-258.png)
- ![alt text](image-259.png)
- Deterministic is predictable whereas randomized is less predictable
- Deterministic allows for equality joins, group by, indexes, and distinct.
- ![alt text](image-260.png)
- We need to generate a column master key to encrypt the databases
- ![alt text](image-261.png)
- Azure Key Vault is extremely secure
- Create a new Keyvault instance on Azure
- ![alt text](image-262.png)
- Premium Keyvault supports HSM keys(Hardware Security Module)
- ![alt text](image-264.png)
- To Encrypt and Decrypt using Column Master Key, we should have the above key permissions selected
- ![alt text](image-265.png)
- ![alt text](image-266.png)
- ![alt text](image-267.png)
- ![alt text](image-268.png)
- Log looks like this
- ![alt text](image-269.png)
- Since we encrypted Address Line 1 and City it looks like this
- ![alt text](image-270.png)
- ![alt text](image-271.png)
- Notice that since we encrypted city deterministics, notice that the first 2 cities probably being the same, have the same encrypted value:
- ![alt text](image-272.png)
- Hence, we can encrypt our database either deterministically or predictably like above case for city or in a randomized manner similar to Address Line 1 above.
- Now how can we see what is the actual data behind what is encrypted
- We will exit SSMS and login back again
- ![alt text](image-273.png)
- ![alt text](image-274.png)
- ![alt text](image-275.png)
- The above error is because we logged in as Jane and not Philip Burton who has an access policy in the Azure Key Vault
- So we need to add a new access policy for Jane
- ![alt text](image-276.png)
- Now try and login back again to SSMS and try to login as Jane and have Always Encrypted enabled
- ![alt text](image-277.png)
- Now we can see the data
- However if we try to search by City we get an error:
- ![alt text](image-278.png)
- This is because City is now an encrypted column and standard way of querying wont work.
- ![alt text](image-279.png)
- We need to enable "Enable Parameterization for Always Encrypted"
- ![alt text](image-280.png)
- In terms of database permissions we have:
- Alter any column master key and Alter any column Encryption Key
- These are needed to create or delete these keys
- We also have "View any column master key" and "view any column encryption key" definition.
- This is needed to access or read the metadata, of these keys to manage them or to query, encrypted columns and
 if you want to grant somebody any of this, then you use something like GRANT view any column master key definition to and the name of the user.

 #### Role Separation
 - There are 2 people involved here: There is a security administrator and Database Administrator
 - Security Admin generates column encryption keys and column master keys. That person has access to the keys and the key store, but he doesnot need access to the database.
 - Database administrator manages the metadata about the keys, but they donot need access to the keys or the key store. 
 - If the above roles need to be given to different people, then we need to use Powershell
 - If they are the same person, then we can use SSMS
 - ![alt text](image-281.png)
 - ![alt text](image-282.png)
 - We can get rid of the encryption by setting the column values back to PlainText
 - ![alt text](image-283.png)

### Always Encrypted vs Transparent Data Encryption(TDE)
- ![alt text](image-284.png)
- TDE is an older technology
- Always encrypted means data is encrypted from the server to the client
- However for TDE, the data is decrypted on the server
- Always Encrypted can encrypt at column level but TDE cannot, it can only encrypt the entire database
- TDE is just ON or OFF

### Implement Always Encrypted with VBS Enclaves
- Always Encrypted protects sensitive data from malware
and users who should have access to the database but not the data.
- It does this by encrypting the data on the client, not allowing it to be in plain text in the database engine.
- Because the data is encrypted, you can only do comparisons based on values being the same or not.
- So, in other words, is this encrypted value the same as this other value which has been encrypted?
- That only works if you're using deterministic encryption, where the encryption is the same each time.
- So, you can't do other things such as data encryption, key rotation, or pattern matching in the database.
- So you can't say, "Does it begin with the letter B?"
- To solve this problem, we can use Always Encrypted with Secure Enclaves
- Enclave means a territory inside some other territory
- It creates a protected part of the memory within the bigger memory
- In that secure enclave we can do computations on the plaintext data
- Always Encrypted in Microsoft SQL Server and Azure SQL Database is a feature that ensures sensitive data is encrypted at all times—both at rest and in transit—and is only decrypted within a secure client application, preventing unauthorized access by database administrators or other privileged users.
- When combined with Virtualization-Based Security (VBS) enclaves, Always Encrypted provides an advanced level of security by enabling secure computations on encrypted data within a trusted execution environment. This allows operations like pattern matching, range queries, and equality comparisons on encrypted columns without exposing plaintext data to the SQL Server engine.
- Always Encrypted in Microsoft SQL Server and Azure SQL Database is a feature that ensures sensitive data is encrypted at all times—both at rest and in transit—and is only decrypted within a secure client application, preventing unauthorized access by database administrators or other privileged users. When combined with Virtualization-Based Security (VBS) enclaves, Always Encrypted provides an advanced level of security by enabling secure computations on encrypted data within a trusted execution environment. This allows operations like pattern matching, range queries, and equality comparisons on encrypted columns without exposing plaintext data to the SQL Server engine.

#### Overview of Always Encrypted
- Always Encrypted protects sensitive data (e.g., credit card numbers, SSNs) by encrypting it at the client side before it’s sent to the database. 
- The encryption is transparent to applications using compatible drivers (e.g., .NET Framework Data Provider for SQL Server). 
- Key components include:
- Column Encryption Key (CEK): Encrypts specific columns in the database.
- Column Master Key (CMK): Protects the CEK and is stored in a trusted key store (e.g., Windows Certificate Store, Azure Key Vault).
- Without VBS enclaves, Always Encrypted has limitations: deterministic encryption leaks data patterns, and randomized encryption doesn’t support operations like LIKE, range queries (>, <), or sorting on encrypted columns because the SQL Server engine cannot process encrypted data.
- A VBS enclave is a secure, isolated region of memory within a Virtualization-Based Security environment, leveraging hardware virtualization (e.g., Intel VT-x, AMD-V) to create a trusted execution environment (TEE).
- It ensures that code and data inside the enclave are protected from unauthorized access, even by the operating system, hypervisor, or privileged users like database administrators.
- In the context of Always Encrypted, VBS enclaves enable rich computations on encrypted data by performing cryptographic operations securely within the enclave.
- Enable Always Encrypted with enclave support by specifying ENCLAVE_COMPUTATIONS in the column encryption key definition.
- Configure the CMK to support enclave computations, typically stored in a trusted key store like Azure Key Vault or Windows Certificate Store.
- Set up attestation to verify the enclave’s trustworthiness. For VBS enclaves, this uses the Windows Defender System Guard attestation protocol, which confirms the enclave’s code and environment are secure.

```sql
CREATE COLUMN ENCRYPTION KEY MyCEK
WITH VALUES
(
    COLUMN_MASTER_KEY = MyCMK,
    ALGORITHM = 'RSA_OAEP',
    ENCRYPTED_VALUE = 0x...,
    ENCLAVE_COMPUTATIONS = 1,
    SIGNATURE = 0x...
);

```
- VBS enclaves enable rich computations on encrypted columns, including:

- Equality comparisons: Supported with deterministic encryption even without enclaves, but enclaves enhance security.
- Range queries: >, <, >=, <=, BETWEEN.
- Pattern matching: LIKE with wildcards (e.g., '%value%').
- Sorting: ORDER BY on encrypted columns.
- Joins: Joins involving encrypted columns.
- To get strongest security use this Sql Database Configuration (DC Series)
- ![alt text](image-285.png)
- We can enable secure enclaves like this
- ![alt text](image-286.png)
- ![alt text](image-287.png)
- ![alt text](image-288.png)
- Once you enable secure enclaves, you cannot disable them


### Implement Dynamic Data Masking
- What if we want people to see first few characters of a column but not all the data. For e.g a credit card with last 4 digits
- We can achieve this with Dynamic Data Masking
- ![alt text](image-289.png)
- This is called Column Level Encryption(CLE)
- Click on Add Mask
- ![alt text](image-290.png)
- ![alt text](image-291.png)
- ![alt text](image-292.png)
- We can exclude some people from viewing masked values which means they can see everything
- Administrators can see everything
- ![alt text](image-293.png)
- ![alt text](image-294.png)
- ![alt text](image-295.png)
- ![alt text](image-296.png)
- We can REVOKE it as well
- Can do it using Azure Powershell also
- ![alt text](image-297.png)

### Configure server and database level firewall rules
- SQL server works off port 1433
- Go to Azure SQL Server
- ![alt text](image-298.png)
- Server level firewall rules are for users and apps to have access to all of the databases in that server. This is also the case for Azure SQL database, which doesn't have a server that you can manage apart from the things that you can see here.
- Database firewall rules are for an individual or app.
- Database rules are checked before server level rules.
- ![alt text](image-299.png)
- Not everyone can do this
- We need atleast SQL Server Contributor or SQL Security Manager Role
- This doesnot apply to Azure SQL Managed Instance
- We can also check these in SSMS
- ![alt text](image-300.png)
- Firewall rules can only be set from the master database only
- **NOTE: We cannot set Database Level Firewall rules using the Azure Portal**
- It can only be done using TSQL in SSMS
- For this we need control database permission at the database level

### Configure TLS
- What TLS does is it seamlessly encrypts data between a database such as SQL server and a client such as yourself.
- It could also be used for instance in banking,encrypting data from the bank to you.
- Packages of data are encrypted from one side and then decrypted from the other side.
- TLS 1.2 uses the stronger SHA256 encryption, improved reliability and better performance
- TLS creates a secure session and takes less time to connect.
- ![alt text](image-301.png)
- Some non-microsoft drivers dont by default use TLS 1.2, they are on older version of TLS, hence we get the options
- We can also set TLS version in powershell with this command
- ![alt text](image-302.png)
- ![alt text](image-303.png)


## Implementing Compliance Controls for sensitive data
### Apply a Data Classification Strategy
- Sensitive data includes data privacy, regulatory and national requirements.
- ![alt text](image-304.png)
- ![alt text](image-305.png)
- ![alt text](image-306.png)
- ![alt text](image-307.png)
- The following roles can modify and read the databases' data classification: Owner, Contributor, and SQL security manager.
- The following roles can read the databases' data classification, but not modify: Reader and user access administrator.
- ![alt text](image-308.png)
- We can also manage classifications in T-SQL
- ![alt text](image-309.png)
- We can then view it in Azure Portal
- ![alt text](image-310.png)
- ![alt text](image-311.png)

### Configure Server and Database Audits
- We can use auditing to retain a trail of selected database actions, report on database activities using pre-configured reports on the dashboard, and analyze reports for suspicious events, unusual activity, and trends.
- It's not supported for premium storage or hierarchical namespace.
- Audit Events are written to Append Blobs in Blob Storage
- We have Server Policy Audits
- They always apply to all databases
- We can do server policy audits or database level audits
- The default auditing policy includes batch completed group, that's for all the queries installed procedures,
and successful database and failed database authentication group, so that's success and failed logins.
- 4000 characters of data is stored in an audit
- ![alt text](image-312.png)
- ![alt text](image-313.png)
- ![alt text](image-314.png)
- ![alt text](image-315.png)
- Event Hub allows us to setup a stream to consume audit level events and write them to a target
- ![alt text](image-316.png)
- ![alt text](image-317.png)
- Go to the database and view audit logs
- ![alt text](image-318.png)
- Go to SSMS
- ![alt text](image-319.png)
- ![alt text](image-320.png)
- ![alt text](image-321.png)
- ![alt text](image-322.png)
- ![alt text](image-323.png)
- ![alt text](image-324.png)
- Microsoft recommends server-level auditing


### Implement Data Change Tracking
- Note Change Tracking(CT) is different from Change Data Capture(CDC)
- While both CT and CDC can be used in Azure SQL Database, only CDC can be used in Azure SQL Managed Instance.
- What does Change Tracking do?
- Let's suppose that you have a table like SalesLT.address. Now suppose a row gets changed or a particular column gets changed. Well, that's what changed tracking tracks.
- So for instance, I could tell you that this row, this column is changed.
- However, it doesn't track how many times something gets changed.
- Neither does it track historic data.
- So I couldn't go back and say what it was changed from.
- It is more lightweight or requires less storage than a feature that would do all that CDC, "change data capture".
- What is CT used for?
- It enables applications to determine which rows have changed and then only request the new rows.
- So that can save a lot of time when you open up an app.
- It doesn't have to reload the entire database, just things which are changed.
- The data is stored in an in-memory roster and flushed on
every checkpoint to the internal data.
- In other words, it is kept in memory and then saved every so often.
- ![alt text](image-325.png)
- We can do it in UI in Database Properties
- ![alt text](image-326.png)
- We can setup CT even at the Table Level
- ![alt text](image-327.png)
- ![alt text](image-328.png)
- If we want to disable CT, we need to disable it on all the tables before we disable it on the database
- ![alt text](image-329.png)
- ![alt text](image-330.png)

### How can we make use of Change Tracking? 
- Get the last synced
- ![alt text](image-331.png)
- Change Tracking in SQL Server and Azure SQL Database is a lightweight feature that tracks changes (inserts, updates, deletes) to rows in a table, enabling applications to efficiently identify and synchronize only the modified data. By using Change Tracking, you can update an application’s data (e.g., a cache, a secondary database, or a client-side dataset) based on what has changed in a specific table, reducing overhead compared to full table scans or manual tracking.
- Change Tracking records changes to rows in a user table by maintaining a version number and minimal metadata about the type of change (insert, update, delete). It is designed for scenarios where an application needs to incrementally synchronize data with a database table.
- Tracks changes at the row level, not column level (it tells you which rows changed, not which columns).
- Stores the primary key of changed rows and the operation type (I for insert, U for update, D for delete).
- Uses a versioning system to indicate the state of the database at a given point.
- Lightweight and integrated into SQL Server, with minimal performance impact compared to alternatives like Change Data Capture (CDC).
- Change Tracking is ideal for applications that need to:

- Periodically refresh a cache or local dataset.
- Synchronize data between a primary database and a  secondary system (e.g., a reporting database or mobile app).
- Detect changes for incremental ETL processes.
- Applications query the changes using functions like CHANGETABLE() to retrieve the primary keys of modified rows and the operation type since a specific version.
- The application uses this information to fetch the updated data and apply it to the target system (e.g., update a cache or synchronize a dataset).
```sql
ALTER DATABASE YourDatabase
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

ALTER TABLE dbo.YourTable
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = OFF);


-- Create a Table
CREATE TABLE dbo.Customers (
    CustomerID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Email NVARCHAR(100),
    LastModified DATETIME
);
ALTER TABLE dbo.Customers
ENABLE CHANGE_TRACKING;

-- Initialize Synchronization Point or a baseline version from which to detect future changes
SELECT CHANGE_TRACKING_CURRENT_VERSION() AS CurrentVersion;
```
- Store this version number (e.g., 0) in the application or a persistent store (e.g., a configuration file, database table, or cache). This is the last sync version the application will use to query changes.
- When the application needs to update its data, query the changes since the last sync version using the CHANGETABLE function. This function returns the primary keys of changed rows, the operation type, and the version of the change.
```sql
DECLARE @LastSyncVersion BIGINT = 0; -- Replace with the application's last sync version
SELECT 
    CT.CustomerID,
    CT.SYS_CHANGE_OPERATION AS Operation,
    CT.SYS_CHANGE_VERSION AS ChangeVersion,
    C.Name,
    C.Email,
    C.LastModified
FROM 
    CHANGETABLE(CHANGES dbo.Customers, @LastSyncVersion) AS CT
LEFT JOIN 
    dbo.Customers AS C ON CT.CustomerID = C.CustomerID;

```
- CHANGETABLE(CHANGES dbo.Customers, @LastSyncVersion): Returns changes to the Customers table since @LastSyncVersion.
- ![alt text](image-332.png)
- The application processes the change data to update its dataset, cache, or secondary system. For each row in the result set:
- Insert (I): Add the new row (e.g., insert into a local cache or secondary database).
- Update (U): Update the existing row with the new values (e.g., update the Name and Email in the cache).
- Delete (D): Remove the row from the application’s dataset or mark it as deleted.
- We can do this inside a C# application as follows:
```c#
using (var connection = new SqlConnection(connectionString))
{
    connection.Open();
    long lastSyncVersion = GetLastSyncVersion(); // Retrieve from app storage
    var command = new SqlCommand(
        @"SELECT CT.CustomerID, CT.SYS_CHANGE_OPERATION, CT.SYS_CHANGE_VERSION, 
                 C.Name, C.Email, C.LastModified
          FROM CHANGETABLE(CHANGES dbo.Customers, @LastSyncVersion) AS CT
          LEFT JOIN dbo.Customers AS C ON CT.CustomerID = C.CustomerID",
        connection);
    command.Parameters.AddWithValue("@LastSyncVersion", lastSyncVersion);

    using (var reader = command.ExecuteReader())
    {
        while (reader.Read())
        {
            int customerId = reader.GetInt32(0);
            string operation = reader.GetString(1);
            long changeVersion = reader.GetInt64(2);

            switch (operation)
            {
                case "I": // Insert
                    var newCustomer = new Customer
                    {
                        CustomerId = customerId,
                        Name = reader.IsDBNull(3) ? null : reader.GetString(3),
                        Email = reader.IsDBNull(4) ? null : reader.GetString(4)
                    };
                    AddToCache(newCustomer); // Add to app cache
                    break;
                case "U": // Update
                    var updatedCustomer = new Customer
                    {
                        CustomerId = customerId,
                        Name = reader.IsDBNull(3) ? null : reader.GetString(3),
                        Email = reader.IsDBNull(4) ? null : reader.GetString(4)
                    };
                    UpdateCache(updatedCustomer); // Update cache
                    break;
                case "D": // Delete
                    RemoveFromCache(customerId); // Remove from cache
                    break;
            }
        }
    }

    // Update the last sync version
    var newVersionCommand = new SqlCommand("SELECT CHANGE_TRACKING_CURRENT_VERSION()", connection);
    long newSyncVersion = (long)newVersionCommand.ExecuteScalar();
    SaveLastSyncVersion(newSyncVersion); // Store new version
}

```
- After processing changes, update the application’s stored last sync version to the latest database version (retrieved via CHANGE_TRACKING_CURRENT_VERSION()). This ensures the next sync starts from the most recent changes.

```sql
SELECT CHANGE_TRACKING_CURRENT_VERSION() AS NewSyncVersion;

```
- Store NewSyncVersion (e.g., 3 in the example) in the application for the next synchronization.
- Use a scheduling mechanism (e.g., SQL Server Agent, Azure Functions, or a cron job) to run the sync process periodically (e.g., every 5 minutes or daily).
- Ensure the sync frequency aligns with the CHANGE_RETENTION period to avoid missing changes due to cleanup.
- Monitor Change Tracking overhead using SQL Server’s Dynamic Management Views (DMVs), such as sys.dm_tran_commit_table, to track version growth.
- ![alt text](image-333.png)
- Use an Azure Function to periodically run the Change Tracking sync process.
- Store the last sync version in Azure Cosmos DB or Azure Table Storage.
- Update a secondary Azure SQL Database or Azure Cache for Redis with the changed data.
- ![alt text](image-334.png)
- ![alt text](image-335.png)

### Using Change Data Capture(CDC)
- We need to upgrade from the Basic Pricing Tier
- CDC can be used across all 3 Azure Sql DB, Managed Instance and SQL on VM
- ![alt text](image-336.png)
- ![alt text](image-337.png)
- ![alt text](image-338.png)
- ![alt text](image-339.png)
- LSN: Log Sequence Number
- ![alt text](image-340.png)
- ![alt text](image-341.png)
- ![alt text](image-342.png)
- CDC needs minimum 100eDTUs to work
- CDC cannot be used in Elastic Pool with vCore less than 1 or eDTU less than 100

### Perform Vulnerable Assessment
- We can use Azure Defender for SQL for 15$ per server per month
- ![alt text](image-343.png)
- ![alt text](image-344.png)
- ![alt text](image-345.png)
- ![alt text](image-346.png)
- ![alt text](image-347.png)
- ![alt text](image-348.png)
- ![alt text](image-349.png)
- ![alt text](image-350.png)
- ![alt text](image-351.png)

### Using Azure Purview
- Azure Purview catalogs our data whether it is on-prem or in a cloud using SaaS
- Microsoft Purview (formerly Azure Purview) is a unified data governance and compliance platform designed to help organizations manage, secure, and gain insights from their data across on-premises, multi-cloud, and software-as-a-service (SaaS) environments.
- It provides tools for data discovery, classification, cataloging, lineage tracking, and compliance management, enabling organizations to maintain control over their data estate while ensuring regulatory compliance and enhancing data-driven decision-making.
- Microsoft Purview is a cloud-native, fully managed service that creates a **holistic, up-to-date map** of an organization’s data landscape.
- It combines data governance (from the former Azure Purview), data security, and risk and compliance solutions (from Microsoft 365 compliance tools) into a single platform. It addresses challenges like data silos, lack of visibility, and compliance requirements by automating data discovery, classifying sensitive data, and providing actionable insights.
- ![alt text](image-352.png)
- ![alt text](image-353.png)
- ![alt text](image-354.png)
-  DataMap: this captures metadata that's information about data from the various sources by scanning and classifying it.
-  DataCatalog: Helps you find data with classification or metadata filters.
- Data Insights: Allow us to see where sensitive data is and how it flows from one data source to another. For instance, we've got sensitivity levels.
- ![alt text](image-355.png)
- ![alt text](image-356.png)
- ![alt text](image-357.png)
- ![alt text](image-358.png)
- ![alt text](image-359.png)
- ![alt text](image-360.png)
- ![alt text](image-361.png)
- ![alt text](image-362.png)
- ![alt text](image-363.png)
- ![alt text](image-364.png)
- ![alt text](image-365.png)
- ![alt text](image-366.png)
- ![alt text](image-367.png)
- ![alt text](image-368.png)
- ![alt text](image-369.png)
- ![alt text](image-370.png)
- ![alt text](image-371.png)
- ![alt text](image-372.png)
- ![alt text](image-373.png)
- ![alt text](image-374.png)
- ![alt text](image-375.png)
- ![alt text](image-376.png)
- ![alt text](image-377.png)
- ![alt text](image-378.png)
- ![alt text](image-379.png)
- ![alt text](image-380.png)

## Implementing Azure SQL Database Ledger
- Basically we need to know that this data inside a table has not tampered with.
- The Azure SQL Database Ledger is a feature that provides tamper-evident and verifiable data integrity for database records by leveraging blockchain-inspired technology.
- It ensures that data in a database cannot be altered or deleted without leaving a traceable record, making it ideal for scenarios requiring high trust, auditability, and compliance (e.g., financial systems, supply chain, or regulatory reporting).
- The principle behind Azure SQL Database Ledger is to create an immutable, cryptographically verifiable ledger of all database changes, using cryptographic hashing and a blockchain-like structure to guarantee data integrity and detect unauthorized modifications.
- The Azure SQL Database Ledger is built on the idea of immutable record-keeping and cryptographic verification, similar to blockchain but optimized for relational databases.
- Trust is maintained: Even privileged users (e.g., database administrators) cannot alter data without leaving evidence.
- This is achieved by:
- Tracking all changes to a table’s data (inserts, updates, deletes) in a ledger table.
- Generating cryptographic hashes for each change to create a tamper-evident chain of records.
- Storing periodic database digests (hashes of the database state) in an immutable external store (e.g., Azure Blob Storage or Azure Confidential Ledger) for independent verification.
- The ledger acts like a digital "audit trail" that ensures the database’s history is complete, unchanged, and verifiable, protecting against unauthorized modifications, even by insiders.
- ![alt text](image-383.png)
- The Ledger feature integrates seamlessly with Azure SQL Database, requiring minimal application changes. It operates at the table level, with two main types of tables: ledger tables and history tables, supported by cryptographic mechanisms and external storage for verification.
- A **ledger table** is a user table configured to track all changes immutably. It stores the current state of the data (like a regular table) but is associated with a history table that records all past changes.
- When a table is created or altered as a ledger table, it automatically tracks all transactions (inserts, updates, deletes).
- Each row in a ledger table includes additional columns:
- ledger_start_transaction_id: The ID of the transaction that created or last updated the row.
- ledger_end_transaction_id: The ID of the transaction that deleted the row (NULL if the row is still active).
- ledger_start_sequence_number: A sequence number for ordering operations within a transaction.
```sql
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Email NVARCHAR(100)
)
WITH (LEDGER = ON);
```
- History Tables are Automatically created for each ledger table to store the historical versions of rows (previous states before updates or deletes).
- For every update or delete, the old row is moved to the history table, preserving the full change history.
- The history table is system-managed and can be queried to view past states or audit changes.
```sql
SELECT * FROM sys.ledger_table_history WHERE table_name = 'Customers';
```
- Transaction Hashes: Each transaction that modifies a ledger table generates a cryptographic hash (using SHA-256) based on the data changed and the transaction’s metadata.
- Transactions are grouped into ledger blocks, where each block contains:
- A hash of the block’s transactions.
- A reference to the hash of the previous block, forming a chain of blocks (like a blockchain).
- If a row in the ledger table or history table is altered, the hash of the affected block will no longer match, making tampering detectable.
- A database digest is a cryptographic hash of the entire database’s ledger state at a specific point in time, summarizing all ledger blocks up to that point.
- Digests are periodically generated and stored in an immutable external store, such as:
- Azure Blob Storage (with immutability enabled).
- Azure Confidential Ledger (a blockchain-based service for higher trust).
- Digests allow independent verification of the database’s integrity by comparing the current state to the stored digest.
- Auditors or applications can verify the database’s integrity by:
- Querying the ledger blocks and their hashes using system views (e.g., sys.database_ledger_blocks).
- Comparing the computed hash of the current database state to the stored digest in the external store.
- If any data in the ledger table, history table, or system metadata is altered, the hash chain will break, and verification will fail.
- Azure SQL Database provides stored procedures like sys.sp_verify_database_ledger to automate verification.
```sql
EXEC sys.sp_verify_database_ledger
    @digest = '{"block_id": 123, "hash": "0x...", "storage": "AzureBlob", "location": "https://..."}';

```
- Ledger tables and history tables are append-only, ensuring no data is overwritten or deleted without a trace.
- Cryptographic hashes link transactions and blocks, making unauthorized changes detectable.
- All changes are recorded in a verifiable format, accessible via system views and history tables.
- External digests provide a trusted reference point for third-party audits.
- Unlike full blockchain systems, Ledger is optimized for relational databases, minimizing performance overhead while maintaining strong integrity guarantees.

### Implement Azure SQL Database Ledger: Creating Updateable Ledger Table
- ![alt text](image-384.png)
- ![alt text](image-385.png)
- Create a Ledger Table
- ![alt text](image-386.png)
- ![alt text](image-387.png)
- ![alt text](image-388.png)
- History Table is not visible
- ![alt text](image-389.png)
- ![alt text](image-390.png)
- Ledger History Table is part of the Updateable Ledger Table itself in the tree view
- ![alt text](image-391.png)
- ![alt text](image-392.png)
- ![alt text](image-393.png)
- ![alt text](image-394.png)
- Notice the Sequence Number restarts from 0
- ![alt text](image-395.png)
- ![alt text](image-396.png)
- We can create an Append-only Ledger Table
- ![alt text](image-397.png)
- ![alt text](image-398.png)
- ![alt text](image-399.png)
- ![alt text](image-400.png)
- ![alt text](image-401.png)
- ![alt text](image-402.png)
- ![alt text](image-403.png)
- ![alt text](image-404.png)

#### Now that we have these ledger tables, how do we make sure data is not tampered with
- ![alt text](image-405.png)
- ![alt text](image-406.png)
- ![alt text](image-407.png)
- ![alt text](image-408.png)
- ![alt text](image-409.png)


### Implementing Row Level Security
- Row-Level Security (RLS) in Azure SQL Database and SQL Server is a feature that restricts access to rows in a table based on user characteristics, such as their identity, role, or context. It allows you to control which rows a user can view or modify without altering the application code, ensuring data security and compliance. RLS is particularly useful for multi-tenant applications, sensitive data protection, or scenarios where users should only access their own data (e.g., a salesperson seeing only their clients’ records).
- ![alt text](image-410.png)
- RLS is available for SQL Server 2016 and later
- RLS works by applying a security predicate (a filter or access rule) to queries on a table. The predicate is defined in a security policy and evaluated for each row during query execution, transparently filtering out rows the user is not authorized to access.
- Security Predicate: A function that determines whether a user can access a row based on conditions (e.g., matching user ID or role).
- Filter Predicate: Restricts rows returned by SELECT, UPDATE, or DELETE queries (read access control).
- Block Predicate: Prevents INSERT, UPDATE, or DELETE operations on specific rows (write access control).
- Security Policy: A database object that binds predicates to tables and enforces RLS.
- Transparency: RLS is enforced at the database level, so applications don’t need to modify queries to enforce row restrictions. For example, in a Customers table, RLS can ensure that each salesperson only sees rows where the SalespersonID matches their user ID.

```sql
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Email NVARCHAR(100),
    SalespersonID NVARCHAR(128), -- Matches the user’s database login or context
    Region NVARCHAR(50)
);

-- Insert sample data
INSERT INTO Customers (CustomerID, Name, Email, SalespersonID, Region)
VALUES 
    (1, 'John Doe', 'john@doe.com', 'salesperson1', 'North'),
    (2, 'Jane Smith', 'jane@smith.com', 'salesperson2', 'South'),
    (3, 'Bob Jones', 'bob@jones.com', 'salesperson1', 'North');

-- Create Database Users
CREATE LOGIN salesperson1 WITH PASSWORD = 'SecurePass123!';
CREATE LOGIN salesperson2 WITH PASSWORD = 'SecurePass456!';

CREATE USER salesperson1 FOR LOGIN salesperson1;
CREATE USER salesperson2 FOR LOGIN salesperson2;

-- Grant read and write permissions on the table
GRANT SELECT, INSERT, UPDATE, DELETE ON Customers TO salesperson1;
GRANT SELECT, INSERT, UPDATE, DELETE ON Customers TO salesperson2;

-- For Azure Entra ID use this
CREATE USER [salesperson1@yourdomain.com] FROM EXTERNAL PROVIDER;
CREATE USER [salesperson2@yourdomain.com] FROM EXTERNAL PROVIDER;

GRANT SELECT, INSERT, UPDATE, DELETE ON Customers TO [salesperson1@yourdomain.com];
GRANT SELECT, INSERT, UPDATE, DELETE ON Customers TO [salesperson2@yourdomain.com];

-- Create a Security Predicate Function
-- Create an inline table-valued function (TVF) that defines the access logic. The function returns rows the user is allowed to access based on their identity or context. The function typically uses USER_NAME(), SUSER_NAME(), or a session context to determine the user.

CREATE SCHEMA Security;
GO

CREATE FUNCTION Security.fn_securitypredicate (@SalespersonID AS NVARCHAR(128))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @SalespersonID = USER_NAME() OR USER_NAME() = 'dbo';
GO


-- Create a security policy to apply the predicate function to the table. The policy defines how the predicate filters or blocks access.

CREATE SECURITY POLICY CustomerFilter
ADD FILTER PREDICATE Security.fn_securitypredicate(SalespersonID) 
ON dbo.Customers
WITH (STATE = ON);

```
- Logic: The function checks if the SalespersonID column matches the current user’s name (USER_NAME()). It also allows the dbo user unrestricted access (e.g., for administrators).
- SCHEMABINDING: Ensures the function is bound to the table’s schema, improving performance and security.
- USER_NAME(): Returns the database user name. Use SUSER_NAME() for SQL login names or SESSION_USER for session context, depending on your authentication setup.
- FILTER PREDICATE: Restricts rows returned by SELECT, UPDATE, or DELETE queries. For example, salesperson1 will only see rows where SalespersonID = 'salesperson1'.
- STATE = ON: Enables the policy. Set to OFF to disable RLS temporarily.
- To also restrict write operations, add block predicates:
```sql
CREATE SECURITY POLICY CustomerFilter
ADD FILTER PREDICATE Security.fn_securitypredicate(SalespersonID) ON dbo.Customers,
ADD BLOCK PREDICATE Security.fn_securitypredicate(SalespersonID) ON dbo.Customers AFTER INSERT,
ADD BLOCK PREDICATE Security.fn_securitypredicate(SalespersonID) ON dbo.Customers BEFORE UPDATE,
ADD BLOCK PREDICATE Security.fn_securitypredicate(SalespersonID) ON dbo.Customers BEFORE DELETE
WITH (STATE = ON);

```
- Block Predicates:
- AFTER INSERT: Prevents inserting rows unless the SalespersonID matches the user.
- BEFORE UPDATE: Prevents updating rows unless the user owns them.
- BEFORE DELETE: Prevents deleting rows unless the user owns them.

#### Test Row-Level Security
- Test RLS by connecting as different users and running queries.

#### Monitor Performance
- Use SQL Server’s query execution plans or Dynamic Management Views (DMVs) like sys.dm_exec_query_stats to assess RLS impact on query performance.
Audit Access: Combine RLS with Azure SQL Database auditing or Microsoft Purview to track who accesses sensitive data.
- ![alt text](image-411.png)
- ![alt text](image-412.png)
- ![alt text](image-414.png)
- ![alt text](image-415.png)
- ![alt text](image-416.png)
- ![alt text](image-417.png)
- ![alt text](image-418.png)
- ![alt text](image-419.png)
- ![alt text](image-420.png)
- ![alt text](image-421.png)
- ![alt text](image-422.png)
- Turn the security policy OFF and you can see everything
- Below is a concise tabular summary of the steps to implement **Row-Level Security (RLS)** in Azure SQL Database or SQL Server, based on the detailed explanation provided earlier.

| **Step** | **Description** | **Example (T-SQL)** |
|----------|-----------------|---------------------|
| **1. Set Up Table** | Create or use a table with a column to associate rows with users (e.g., `SalespersonID`). | ```sql CREATE TABLE Customers (CustomerID INT PRIMARY KEY,   Name NVARCHAR(100),   SalespersonID NVARCHAR(128))``` |
| **2. Create Users** | Create database users or logins (e.g., SQL logins or Azure AD users) and grant table permissions. | ```sql CREATE USER salesperson1 FOR LOGIN salesperson1;GRANT SELECT, INSERT, UPDATE, DELETE ON Customers TO salesperson1;``` |
| **3. Create Predicate Function** | Define an inline table-valued function (TVF) to check user access based on a column (e.g., match `SalespersonID` with `USER_NAME()`). | ```sql CREATE SCHEMA Security; GO CREATE FUNCTION Security.fn_securitypredicate (@SalespersonID NVARCHAR(128)) RETURNS TABLE WITH SCHEMABINDING AS RETURN SELECT 1 AS fn_securitypredicate_result WHERE @SalespersonID = USER_NAME();``` |
| **4. Create Security Policy** | Create a security policy to apply the predicate function as a filter (and optionally block) predicate to the table. | ```sql CREATE SECURITY POLICY CustomerFilter ADD FILTER PREDICATE Security.fn_securitypredicate(SalespersonID) ON dbo.Customers WITH (STATE = ON)``` |
| **5. Test RLS** | Test access by querying as different users to verify row restrictions. | ```sql EXECUTE AS USER = 'salesperson1' SELECT * FROM Customers;REVERT``` |
| **6. Monitor and Secure** | Grant function permissions, monitor performance, and enable auditing for compliance. | ```sql GRANT SELECT ON Security.fn_securitypredicate TO PUBLIC``` |

---

### **Notes**
- **Filter Predicate**: Restricts `SELECT`, `UPDATE`, `DELETE` queries to authorized rows.
- **Block Predicate** (optional): Add to prevent unauthorized `INSERT`, `UPDATE`, or `DELETE` operations (e.g., `ADD BLOCK PREDICATE ... AFTER INSERT`).
- **Best Practices**: Use `SCHEMABINDING` in the TVF, optimize predicates, secure user context, and test thoroughly.
- **Integration**: Combine with **Change Tracking** to sync only authorized rows or **Azure SQL Database Ledger** for tamper-evident data.


#### Different Types of Functions in SQL

- A Table-Valued Function (TVF) in SQL Server and Azure SQL Database is a user-defined function that returns a table as its output, allowing it to be used in SQL queries like a regular table or view. TVFs are commonly used to encapsulate complex logic, return rowsets for further querying, or implement reusable data transformations.
- SQL Server categorizes functions into two broad groups: User-Defined Functions (UDFs) and System Functions. User-Defined Functions include several types, while System Functions are built-in utilities provided by SQL Server.
- Scalar Functions
- Definition: A Scalar Function returns a single value (e.g., a number, string, or date) based on input parameters. It performs calculations or transformations and is typically used in SELECT, WHERE, or SET clauses.
- Purpose: Encapsulates logic for computations, formatting, or data manipulation that returns one value per invocation.
```sql
CREATE FUNCTION dbo.CalculateCustomerTotal (@CustomerID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Total DECIMAL(10,2);
    SELECT @Total = SUM(Amount)
    FROM dbo.Orders
    WHERE CustomerID = @CustomerID;
    RETURN ISNULL(@Total, 0);
END;
GO

```
- Aggregate Functions (System and User-Defined)
- Aggregate Functions operate on a set of rows and return a single value summarizing the data (e.g., SUM, COUNT, AVG). SQL Server provides built-in aggregate functions, and users can create User-Defined Aggregate (UDA) Functions using CLR (Common Language Runtime) integration.
- Purpose: Summarizes data across multiple rows, commonly used in GROUP BY queries.
```sql
SELECT SalespersonID, SUM(Amount) AS TotalSales
FROM dbo.Orders
GROUP BY SalespersonID;
```
- System Functions
- Definition: Built-in functions provided by SQL Server for various purposes, including string manipulation, date/time operations, mathematical calculations, metadata retrieval, and security checks.
- Purpose: Perform common tasks without requiring user-defined logic.
- Categories:
- String Functions: LEN, CONCAT, SUBSTRING.
- Date/Time Functions: GETDATE, DATEADD, DATEDIFF.
- Mathematical Functions: ROUND, ABS, POWER.
- Security Functions: USER_NAME, SUSER_NAME, IS_MEMBER (used in RLS).
- Metadata Functions: OBJECT_ID, DB_NAME.
- System Statistical Functions: @@ROWCOUNT, @@VERSION.
```sql
CREATE FUNCTION Security.fn_securitypredicate (@SalespersonID AS NVARCHAR(128))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @SalespersonID = USER_NAME();

```
- ![alt text](image-413.png)

### Configure Advanced Threat Protection / Microsoft Defender for SQL
- Available for Azure SQL Database, Azure Managed Instance, Azure SQL on VM
- We need to prevent SQL Injection Attacks
- Following is an example of a SQL Injection Attack where we ask the user for a parameter and the user specifies the parameter along with a SQL statement
- ![alt text](image-423.png)
- Azure Defender can help us prevent this
- ![alt text](image-424.png)
- ![alt text](image-425.png)
- ![alt text](image-426.png)
- ![alt text](image-427.png)
- ![alt text](image-428.png)
- ![alt text](image-429.png)

## Monitor Activity and Performance
