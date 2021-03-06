drop Procedure [dbo].[SP_TAOTAIKHOAN]
go

SET QUOTED_IDENTIFIER ON
go
SET ANSI_NULLS ON
go
CREATE PROC [dbo].[SP_TAOTAIKHOAN]
	@LGNAME VARCHAR(50),
	@PASS VARCHAR(50),
	@USERNAME VARCHAR(50),
	@ROLE VARCHAR(50)
AS
BEGIN
	DECLARE @RET INT
	EXEC @RET = SP_ADDLOGIN @LGNAME, @PASS, 'QL_LAZADA'

	IF (@RET = 1)  --LOGIN BI TRUNG
		RETURN 1;

	EXEC @RET = SP_GRANTDBACCESS @LGNAME, @USERNAME
	IF (@RET = 1) --USER BI TRUNG
	BEGIN
		EXEC SP_DROPLOGIN @LGNAME
		RETURN 2
	END
	EXEC SP_ADDROLEMEMBER @ROLE, @USERNAME

	IF @ROLE = 'ADMIN'
	BEGIN
		EXEC SP_ADDROLEMEMBER @LGNAME, 'SYSADMIN'
		EXEC SP_ADDROLEMEMBER @LGNAME, 'SECURITYADMIN'
		EXEC SP_ADDROLEMEMBER @LGNAME, 'PROCESSADMIN'
	END

	IF @ROLE = 'ADMINKHUVUC'
	BEGIN
		EXEC SP_ADDROLEMEMBER @LGNAME, 'SYSADMIN'
		EXEC SP_ADDROLEMEMBER @LGNAME, 'SECURITYADMIN'
		EXEC SP_ADDROLEMEMBER @LGNAME, 'PROCESSADMIN'
	END

	IF @ROLE = 'KHACHHANG'
	BEGIN
		EXEC SP_ADDROLEMEMBER @LGNAME, 'PROCESSADMIN'
	END

	IF @ROLE = 'NHACUNGCAP'
	BEGIN
		EXEC SP_ADDROLEMEMBER @LGNAME, 'PROCESSADMIN'
	END
END
go
