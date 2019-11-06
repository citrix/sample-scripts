-- Author: Mark Dear
-- Date: 06 Nov, 2019

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE [STFSubscriptions]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'p' AND name = 'uspImportSubscriptionData')
DROP PROCEDURE uspImportSubscriptionData;
GO

CREATE PROCEDURE uspImportSubscriptionData
AS
BEGIN	
	DECLARE @RowCounter INT = 0,
			@RecordsImported INT = 0,
			@UserSID NVARCHAR(190),
			@NewUserID INT,
			@ExistingUserID INT,
			@Resource_id NVARCHAR(500),
			@Subscription_ref NVARCHAR(66),
			@SQLAppStatus INT,
			@MetaData NVARCHAR(max),
			@SecMetaData NVARCHAR(max) = NULL;

	-- Remove previous TempImport table
	IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'TempImport')
	DROP TABLE dbo.TempImport;

	--Create Table for BULK SQL INSERT
	CREATE TABLE [TempImport]
	(
		UserSID  NVARCHAR(190) NOT NULL, 
		Subscription_ref NVARCHAR(66) NOT NULL,
		Resource_id NVARCHAR(500) NOT NULL,
		SQLAppStatus int NOT NULL,
		MetaData NVARCHAR(max) NULL
	);

	-- \t = tab field terminator
	-- \r = new line row terminator
	BULK INSERT [TempImport]
	FROM 'c:\SubscriptionsSQL.txt'
	WITH 
	(
		FIELDTERMINATOR ='\t',
		ROWTERMINATOR ='\n',
		ERRORFILE = 'C:\ImportErrorRows.csv'
	);

	SET @RowCounter = 1;

	--Obtain number of records successfully bulk imported
	SET @RecordsImported = (SELECT COUNT(*) FROM TempImport);
	PRINT 'Records Successfully Imported into TempImport from c:\SubscriptionsSQL.txt = ' + cast(@RecordsImported AS VARCHAR);
	
	-- Create indexed version of the TempImport table so data can be selected by ID.
	CREATE TABLE [DataImport]
	(
		ID int IDENTITY(1,1) PRIMARY KEY NOT NULL,
		UserSID  NVARCHAR(190) NOT NULL, 
		Subscription_ref NVARCHAR(66) NOT NULL,
		Resource_id NVARCHAR(500) NOT NULL,
		SQLAppStatus int NOT NULL,
		MetaData NVARCHAR(max) NULL
	);

	INSERT INTO DataImport (UserSID,Resource_id,Subscription_ref,SQLAppStatus,MetaData)
	SELECT UserSID,Resource_id,Subscription_ref,SQLAppStatus,MetaData
	FROM TempImport;

	-- Process row by row to check if UserSID already exists in User Table before attempting to add it
	WHILE @RowCounter <= @RecordsImported
	BEGIN
		SET @UserSID = (SELECT UserSID FROM DataImport WHERE id = @RowCounter);
		SET @Resource_id = (SELECT Resource_id FROM DataImport WHERE id = @RowCounter);
		SET @Subscription_ref = (SELECT Subscription_ref FROM DataImport WHERE id = @RowCounter);
		SET @SQLAppStatus = (SELECT SQLAppStatus FROM DataImport WHERE id = @RowCounter);
		SET @MetaData = (SELECT MetaData FROM DataImport WHERE id = @RowCounter);	
		PRINT 'ImportedRowCounter = ' + cast(@RowCounter AS VARCHAR);	
		PRINT 'UserSID = ' + @UserSID;
		PRINT 'ResourceID = ' + @Resource_id;
		PRINT 'SubscriptionRef = ' + @Subscription_ref;
		PRINT 'Status = ' + cast(@SQLAppStatus AS VARCHAR);
		PRINT 'MetaData = ' + @MetaData;

		IF NOT EXISTS (SELECT username FROM [User] WHERE username = @UserSID)
			BEGIN
				PRINT @UserSID + ' DOES NOT EXIST in the [User] Table'
				PRINT 'Adding UserSID ' + @UserSID + ' to the [User] Table'
				--id, username
				INSERT INTO [User]([username]) VALUES (@UserSID);
				SET @NewUserID = (SELECT id FROM [User] WHERE username = @UserSID);
				PRINT 'New ID for UserSID ' + @UserSID + ' = ' + cast(@NewUserID AS VARCHAR) + CHAR(13);
				--id, subscription_ref, resource_id, user_id, status, metadata, secure_metadata
				INSERT INTO [Subscription]([Subscription_ref],[resource_id],[user_id],[status],[metadata],[secure_metadata]) VALUES (@Subscription_ref,@Resource_id,@NewUserID,@SQLAppStatus,@MetaData,@SecMetaData);
			END
		ELSE
			BEGIN
				PRINT @UserSID + ' already EXISTS in the [User] Table'
				PRINT 'Obtaining Existing ID from the [User] Table for UserSID = ' + @UserSID;
				SET @ExistingUserID = (SELECT id FROM [User] WHERE username = @UserSID)
				PRINT 'Existing ID = ' + cast(@ExistingUserID AS VARCHAR) + CHAR(13);
				--id, subscription_ref, resource_id, user_id, status, metadata, secure_metadata
				INSERT INTO [Subscription]([Subscription_ref],[resource_id],[user_id],[status],[metadata],[secure_metadata]) VALUES (@Subscription_ref,@Resource_id,@ExistingUserID,@SQLAppStatus,@MetaData,@SecMetaData);
			END
		SET @RowCounter = (@RowCounter + 1);
	END
	DROP TABLE [TempImport]
	DROP TABLE [DataImport]
END