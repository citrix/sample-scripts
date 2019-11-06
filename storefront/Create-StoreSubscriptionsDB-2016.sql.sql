-- Author: Mark Dear
-- Date: 06 Nov, 2019

--Path dictated by the SQL Server Version
--SQL Server 2008R2	C:\Program Files\Microsoft SQL Server\MSSQL10_50.<instancename>\MSSQL\DATA\
--SQL Server 2012 	C:\Program Files\Microsoft SQL Server\MSSQL11.<instancename>\MSSQL\DATA\
--SQL Server 2014 	C:\Program Files\Microsoft SQL Server\MSSQL12.<instancename>\MSSQL\DATA\
--SQL Server 2016 	C:\Program Files\Microsoft SQL Server\MSSQL13.<instancename>\MSSQL\DATA\

ALTER DATABASE [STFSubscriptions] SET ANSI_NULL_DEFAULT OFF
ALTER DATABASE [STFSubscriptions] SET ANSI_NULLS OFF
ALTER DATABASE [STFSubscriptions] SET ANSI_PADDING OFF
ALTER DATABASE [STFSubscriptions] SET ANSI_WARNINGS OFF
ALTER DATABASE [STFSubscriptions] SET ARITHABORT OFF
ALTER DATABASE [STFSubscriptions] SET AUTO_CLOSE OFF
ALTER DATABASE [STFSubscriptions] SET AUTO_CREATE_STATISTICS ON
ALTER DATABASE [STFSubscriptions] SET AUTO_SHRINK OFF
ALTER DATABASE [STFSubscriptions] SET AUTO_UPDATE_STATISTICS ON
ALTER DATABASE [STFSubscriptions] SET CURSOR_CLOSE_ON_COMMIT OFF
ALTER DATABASE [STFSubscriptions] SET CURSOR_DEFAULT GLOBAL
ALTER DATABASE [STFSubscriptions] SET CONCAT_NULL_YIELDS_NULL OFF
ALTER DATABASE [STFSubscriptions] SET NUMERIC_ROUNDABORT OFF
ALTER DATABASE [STFSubscriptions] SET QUOTED_IDENTIFIER OFF
ALTER DATABASE [STFSubscriptions] SET RECURSIVE_TRIGGERS OFF
ALTER DATABASE [STFSubscriptions] SET DISABLE_BROKER
ALTER DATABASE [STFSubscriptions] SET AUTO_UPDATE_STATISTICS_ASYNC OFF
ALTER DATABASE [STFSubscriptions] SET DATE_CORRELATION_OPTIMIZATION OFF
ALTER DATABASE [STFSubscriptions] SET TRUSTWORTHY OFF
ALTER DATABASE [STFSubscriptions] SET ALLOW_SNAPSHOT_ISOLATION OFF
ALTER DATABASE [STFSubscriptions] SET PARAMETERIZATION SIMPLE
ALTER DATABASE [STFSubscriptions] SET READ_COMMITTED_SNAPSHOT OFF
ALTER DATABASE [STFSubscriptions] SET HONOR_BROKER_PRIORITY OFF
ALTER DATABASE [STFSubscriptions] SET READ_WRITE
ALTER DATABASE [STFSubscriptions] SET RECOVERY FULL
ALTER DATABASE [STFSubscriptions] SET MULTI_USER
ALTER DATABASE [STFSubscriptions] SET PAGE_VERIFY NONE
ALTER DATABASE [STFSubscriptions] SET DB_CHAINING OFF
GO

--Specify the Store database you wish to configure here
USE [STFSubscriptions]

/****** Object:  Table [dbo].[User]  ******/
-- Just stores schema versioning info.  
-- Not actually used by StoreFront to store subscription data
CREATE TABLE [dbo].[SchemaDetails]
([major_version] [int] NOT NULL,
 [minor_version] [int] NOT NULL,
 [details] [nvarchar](max) NULL
)

INSERT INTO [dbo].[SchemaDetails] ([major_version], [minor_version]) VALUES (2,0)
GO

/****** Object:  Table [dbo].[User]  ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[User]
([id] [int] PRIMARY KEY CLUSTERED IDENTITY(1,1) NOT NULL,
 [username] [nvarchar](190) COLLATE latin1_general_CS_AS_KS NOT NULL,
 CONSTRAINT UniqueSID UNIQUE(username))

CREATE UNIQUE NONCLUSTERED INDEX [UsernameIdx] ON [dbo].[User] 
([username] ASC)
WITH (PAD_INDEX  = OFF, 
	  STATISTICS_NORECOMPUTE  = OFF, 
	  SORT_IN_TEMPDB = OFF, 
	  IGNORE_DUP_KEY = OFF, 
	  DROP_EXISTING = OFF, 
	  ONLINE = OFF, 
	  ALLOW_ROW_LOCKS = ON, 
	  ALLOW_PAGE_LOCKS = OFF) 

/****** Object:  Table [dbo].[Subscription]  ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON 

CREATE TABLE [dbo].[Subscription]
([id] [int] PRIMARY KEY CLUSTERED IDENTITY(1,1) NOT NULL,
 [subscription_ref] [nvarchar](66) COLLATE latin1_general_CS_AS_KS NOT NULL,
 [resource_id] [nvarchar](500) COLLATE latin1_general_CS_AS_KS NOT NULL,
 [user_id] [int] NOT NULL,
 [status] [int] NOT NULL CONSTRAINT [DefaultStatus] DEFAULT ((0)),
 [metadata] [nvarchar](max) NULL,
 [secure_metadata] [nvarchar](max) NULL,
 CONSTRAINT [UniqueUserResource] UNIQUE([user_id],resource_id),
 CONSTRAINT [FKSubscriptionUserId] FOREIGN KEY ([user_id])
 REFERENCES [User] (id)
        ON DELETE CASCADE
		ON UPDATE CASCADE)

CREATE NONCLUSTERED INDEX [UserResourceIdx] ON [dbo].[Subscription] 
([user_id] ASC,
 [resource_id] ASC)
 WITH 
 (PAD_INDEX  = OFF, 
  STATISTICS_NORECOMPUTE  = OFF, 
  SORT_IN_TEMPDB = OFF, 
  IGNORE_DUP_KEY = OFF, 
  DROP_EXISTING = OFF, 
  ONLINE = OFF, 
  ALLOW_ROW_LOCKS  = ON, 
  ALLOW_PAGE_LOCKS  = OFF)

CREATE NONCLUSTERED INDEX [SubscriptionRefIdx] ON [dbo].[Subscription]
([subscription_ref] ASC) WITH 
(PAD_INDEX  = OFF, 
 STATISTICS_NORECOMPUTE  = OFF, 
 SORT_IN_TEMPDB = OFF, 
 IGNORE_DUP_KEY = OFF, 
 DROP_EXISTING = OFF, 
 ONLINE = OFF, 
 ALLOW_ROW_LOCKS  = ON, 
 ALLOW_PAGE_LOCKS  = OFF)

-- Make sure StoreFrontServers exists
-- Needed for AD/Kerberos authentication between StoreFront Servers and SQL Server
USE [master]

IF NOT EXISTS (SELECT loginname FROM master.dbo.syslogins WHERE NAME = 'StoreFrontServers' and dbname = 'STFSubscriptions')
	BEGIN
		CREATE LOGIN [SHAREDSQL\StoreFrontServers] FROM WINDOWS;
		ALTER LOGIN [SHAREDSQL\StoreFrontServers] 
		WITH DEFAULT_DATABASE = [STFSubscriptions];

		-- Create the SQL principal/account for the local security group members
		USE [STFSubscriptions]
		CREATE USER [SubscriptionDBUsers] FOR LOGIN [SHAREDSQL\StoreFrontServers];

		-- Add read/write access to the SQL server
		EXEC sp_addrolemember N'db_datawriter', N'SubscriptionDBUsers';
		EXEC sp_addrolemember N'db_datareader', N'SubscriptionDBUsers';
	END
GO