/* =====================================================================
   Nova Schools — Student Affairs & Fees System
   01_create_schema.sql : creates the database, tables, constraints,
                          indexes and balance views.
   ===================================================================== */


-- USE master;
-- IF DB_ID('NovaSchoolDB') IS NOT NULL
-- BEGIN
--     ALTER DATABASE NovaSchoolDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--     DROP DATABASE NovaSchoolDB;
-- END
-- GO

IF DB_ID('NovaSchoolDB') IS NULL
    CREATE DATABASE NovaSchoolDB;
GO

USE NovaSchoolDB;
GO

/* ---------------------------------------------------------------------
   1) Lookup tables: Stages, Classes, AcademicYears
   --------------------------------------------------------------------- */

CREATE TABLE dbo.Stages (
    StageId    INT IDENTITY(1,1) CONSTRAINT PK_Stages PRIMARY KEY,
    NameAr     NVARCHAR(50) NOT NULL,
    NameEn     NVARCHAR(50) NOT NULL,
    SortOrder  INT          NOT NULL,
    CONSTRAINT UQ_Stages_SortOrder UNIQUE (SortOrder)
);
GO

CREATE TABLE dbo.Classes (
    ClassId    INT IDENTITY(1,1) CONSTRAINT PK_Classes PRIMARY KEY,
    StageId    INT          NOT NULL CONSTRAINT FK_Classes_Stages REFERENCES dbo.Stages(StageId),
    ClassName  NVARCHAR(20) NOT NULL,            -- e.g. 1/A
    Capacity   INT          NOT NULL CONSTRAINT DF_Classes_Capacity DEFAULT (30),
    CONSTRAINT UQ_Classes_Stage_Name UNIQUE (StageId, ClassName),
    CONSTRAINT CK_Classes_Capacity CHECK (Capacity > 0)
);
GO

CREATE TABLE dbo.AcademicYears (
    YearId     INT IDENTITY(1,1) CONSTRAINT PK_AcademicYears PRIMARY KEY,
    Name       NVARCHAR(9) NOT NULL,             -- e.g. 2025/2026
    StartDate  DATE        NOT NULL,
    EndDate    DATE        NOT NULL,
    IsCurrent  BIT         NOT NULL CONSTRAINT DF_AcademicYears_IsCurrent DEFAULT (0),
    CONSTRAINT UQ_AcademicYears_Name UNIQUE (Name),
    CONSTRAINT CK_AcademicYears_Dates CHECK (EndDate > StartDate)
);
GO


CREATE UNIQUE INDEX UX_AcademicYears_OneCurrent
    ON dbo.AcademicYears (IsCurrent) WHERE IsCurrent = 1;
GO

/* ---------------------------------------------------------------------
   2) Students & yearly enrollment
   --------------------------------------------------------------------- */

CREATE TABLE dbo.Students (
    StudentId      INT IDENTITY(1,1) CONSTRAINT PK_Students PRIMARY KEY,
    StudentCode    NVARCHAR(10)  NOT NULL,
    FullName       NVARCHAR(100) NOT NULL,
    BirthDate      DATE          NULL,
    Gender         CHAR(1)       NOT NULL,
    GuardianName   NVARCHAR(100) NULL,
    GuardianPhone  VARCHAR(15)   NULL,
    Status         NVARCHAR(20)  NOT NULL CONSTRAINT DF_Students_Status DEFAULT (N'Active'),
    CreatedAt      DATETIME2(0)  NOT NULL CONSTRAINT DF_Students_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_Students_Code UNIQUE (StudentCode),
    CONSTRAINT CK_Students_Gender CHECK (Gender IN ('M', 'F')),
    CONSTRAINT CK_Students_Status CHECK (Status IN (N'Active', N'Transferred', N'Withdrawn', N'Graduated'))
);
GO

CREATE INDEX IX_Students_FullName ON dbo.Students (FullName);
GO


CREATE TABLE dbo.Enrollments (
    EnrollmentId  INT IDENTITY(1,1) CONSTRAINT PK_Enrollments PRIMARY KEY,
    StudentId     INT          NOT NULL CONSTRAINT FK_Enrollments_Students      REFERENCES dbo.Students(StudentId),
    YearId        INT          NOT NULL CONSTRAINT FK_Enrollments_AcademicYears REFERENCES dbo.AcademicYears(YearId),
    ClassId       INT          NOT NULL CONSTRAINT FK_Enrollments_Classes       REFERENCES dbo.Classes(ClassId),
    EnrolledAt    DATETIME2(0) NOT NULL CONSTRAINT DF_Enrollments_EnrolledAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_Enrollments_Student_Year UNIQUE (StudentId, YearId)   -- قيد واحد للطالب في السنة
);
GO

CREATE INDEX IX_Enrollments_Class ON dbo.Enrollments (ClassId, YearId);
GO

/* ---------------------------------------------------------------------
   3) Fees: template → per-student charges
   --------------------------------------------------------------------- */

CREATE TABLE dbo.FeeSchedules (
    FeeScheduleId  INT IDENTITY(1,1) CONSTRAINT PK_FeeSchedules PRIMARY KEY,
    YearId         INT           NOT NULL CONSTRAINT FK_FeeSchedules_AcademicYears REFERENCES dbo.AcademicYears(YearId),
    StageId        INT           NOT NULL CONSTRAINT FK_FeeSchedules_Stages        REFERENCES dbo.Stages(StageId),
    FeeType        NVARCHAR(20)  NOT NULL,
    InstallmentNo  TINYINT       NOT NULL,
    Amount         DECIMAL(10,2) NOT NULL,
    DueDate        DATE          NOT NULL,
    CONSTRAINT UQ_FeeSchedules UNIQUE (YearId, StageId, FeeType, InstallmentNo),
    CONSTRAINT CK_FeeSchedules_Type CHECK (FeeType IN (N'Tuition', N'Bus', N'Books', N'Activities')),
    CONSTRAINT CK_FeeSchedules_Amount CHECK (Amount > 0),
    CONSTRAINT CK_FeeSchedules_Installment CHECK (InstallmentNo BETWEEN 1 AND 12)
);
GO

CREATE TABLE dbo.StudentCharges (
    ChargeId       INT IDENTITY(1,1) CONSTRAINT PK_StudentCharges PRIMARY KEY,
    EnrollmentId   INT           NOT NULL CONSTRAINT FK_StudentCharges_Enrollments  REFERENCES dbo.Enrollments(EnrollmentId),
    FeeScheduleId  INT           NOT NULL CONSTRAINT FK_StudentCharges_FeeSchedules REFERENCES dbo.FeeSchedules(FeeScheduleId),
    Amount         DECIMAL(10,2) NOT NULL,
    Discount       DECIMAL(10,2) NOT NULL CONSTRAINT DF_StudentCharges_Discount DEFAULT (0),
    CONSTRAINT UQ_StudentCharges UNIQUE (EnrollmentId, FeeScheduleId),
    CONSTRAINT CK_StudentCharges_Amount CHECK (Amount >= 0),
    CONSTRAINT CK_StudentCharges_Discount CHECK (Discount >= 0 AND Discount <= Amount)
);
GO

/* ---------------------------------------------------------------------
   4) Payments: receipt → allocations to installments
   --------------------------------------------------------------------- */

CREATE TABLE dbo.Payments (
    PaymentId     INT IDENTITY(1,1) CONSTRAINT PK_Payments PRIMARY KEY,
    EnrollmentId  INT           NOT NULL CONSTRAINT FK_Payments_Enrollments REFERENCES dbo.Enrollments(EnrollmentId),
    Amount        DECIMAL(10,2) NOT NULL,
    PaymentDate   DATE          NOT NULL CONSTRAINT DF_Payments_Date DEFAULT (CAST(GETDATE() AS DATE)),
    ReceiptNo     NVARCHAR(20)  NOT NULL,
    Method        NVARCHAR(20)  NOT NULL,
    Notes         NVARCHAR(200) NULL,
    CreatedAt     DATETIME2(0)  NOT NULL CONSTRAINT DF_Payments_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_Payments_Receipt UNIQUE (ReceiptNo),
    CONSTRAINT CK_Payments_Amount CHECK (Amount > 0),
    CONSTRAINT CK_Payments_Method CHECK (Method IN (N'Cash', N'Card', N'BankTransfer', N'Wallet'))
);
GO

CREATE INDEX IX_Payments_Enrollment ON dbo.Payments (EnrollmentId);
GO

CREATE TABLE dbo.PaymentAllocations (
    AllocationId  INT IDENTITY(1,1) CONSTRAINT PK_PaymentAllocations PRIMARY KEY,
    PaymentId     INT           NOT NULL CONSTRAINT FK_PaymentAllocations_Payments       REFERENCES dbo.Payments(PaymentId),
    ChargeId      INT           NOT NULL CONSTRAINT FK_PaymentAllocations_StudentCharges REFERENCES dbo.StudentCharges(ChargeId),
    Amount        DECIMAL(10,2) NOT NULL,
    CONSTRAINT UQ_PaymentAllocations UNIQUE (PaymentId, ChargeId),
    CONSTRAINT CK_PaymentAllocations_Amount CHECK (Amount > 0)
);
GO

CREATE INDEX IX_PaymentAllocations_Charge ON dbo.PaymentAllocations (ChargeId);
GO

/* ---------------------------------------------------------------------
   5) Transfers
   --------------------------------------------------------------------- */

CREATE TABLE dbo.Transfers (
    TransferId    INT IDENTITY(1,1) CONSTRAINT PK_Transfers PRIMARY KEY,
    StudentId     INT           NOT NULL CONSTRAINT FK_Transfers_Students REFERENCES dbo.Students(StudentId),
    TransferDate  DATE          NOT NULL,
    ToSchool      NVARCHAR(150) NOT NULL,
    Reason        NVARCHAR(300) NULL,
    ClearanceNo   NVARCHAR(20)  NULL,         -- رقم شهادة إخلاء الطرف
    CreatedAt     DATETIME2(0)  NOT NULL CONSTRAINT DF_Transfers_CreatedAt DEFAULT (SYSDATETIME())
);
GO

CREATE UNIQUE INDEX UX_Transfers_ClearanceNo
    ON dbo.Transfers (ClearanceNo) WHERE ClearanceNo IS NOT NULL;
GO

/* ---------------------------------------------------------------------
   6) Views: balances are CALCULATED, never stored
   --------------------------------------------------------------------- */

CREATE VIEW dbo.vw_ChargeBalances
AS
SELECT
    sc.ChargeId,
    sc.EnrollmentId,
    fs.FeeType,
    fs.InstallmentNo,
    fs.DueDate,
    sc.Amount - sc.Discount                               AS NetAmount,
    ISNULL(pa.Paid, 0)                                    AS Paid,
    (sc.Amount - sc.Discount) - ISNULL(pa.Paid, 0)        AS Remaining
FROM dbo.StudentCharges sc
JOIN dbo.FeeSchedules  fs ON fs.FeeScheduleId = sc.FeeScheduleId
OUTER APPLY (
    SELECT SUM(a.Amount) AS Paid
    FROM dbo.PaymentAllocations a
    WHERE a.ChargeId = sc.ChargeId
) pa;
GO

CREATE VIEW dbo.vw_StudentBalances
AS
SELECT
    e.EnrollmentId,
    s.StudentId,
    s.StudentCode,
    s.FullName,
    s.Status,
    y.YearId,
    y.Name                                   AS AcademicYear,
    st.NameAr                                AS StageAr,
    st.NameEn                                AS StageEn,
    c.ClassName,
    ISNULL(b.TotalDue, 0)                    AS TotalDue,
    ISNULL(b.TotalPaid, 0)                   AS TotalPaid,
    ISNULL(b.Remaining, 0)                   AS Remaining,
    ISNULL(b.Overdue, 0)                     AS Overdue
FROM dbo.Enrollments   e
JOIN dbo.Students      s  ON s.StudentId = e.StudentId
JOIN dbo.AcademicYears y  ON y.YearId    = e.YearId
JOIN dbo.Classes       c  ON c.ClassId   = e.ClassId
JOIN dbo.Stages        st ON st.StageId  = c.StageId
OUTER APPLY (
    SELECT
        SUM(cb.NetAmount)  AS TotalDue,
        SUM(cb.Paid)       AS TotalPaid,
        SUM(cb.Remaining)  AS Remaining,
        SUM(CASE WHEN cb.DueDate < CAST(GETDATE() AS DATE) THEN cb.Remaining ELSE 0 END) AS Overdue
    FROM dbo.vw_ChargeBalances cb
    WHERE cb.EnrollmentId = e.EnrollmentId
) b;
GO

PRINT N'✅ NovaSchoolDB schema created successfully.';
