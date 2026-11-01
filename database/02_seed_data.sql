USE NovaSchoolDB;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM dbo.Students)
BEGIN
    PRINT 'Seed data already exists. Nothing was inserted.';
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Stages (NameAr, NameEn, SortOrder)
    VALUES
        (N'كي جي 1',               N'KG 1',      1),
        (N'كي جي 2',               N'KG 2',      2),
        (N'الصف الأول الابتدائي',   N'Primary 1', 3),
        (N'الصف الثاني الابتدائي',  N'Primary 2', 4),
        (N'الصف الثالث الابتدائي',  N'Primary 3', 5),
        (N'الصف الرابع الابتدائي',  N'Primary 4', 6);

    INSERT INTO dbo.Classes (StageId, ClassName, Capacity)
    SELECT s.StageId, CONCAT(REPLACE(s.NameEn, ' ', ''), N'-', v.Section), 30
    FROM dbo.Stages s
    CROSS JOIN (VALUES (N'A'), (N'B')) v(Section);

    INSERT INTO dbo.AcademicYears (Name, StartDate, EndDate, IsCurrent)
    VALUES (N'2026/2027', '2026-09-01', '2027-06-30', 1);

    DECLARE @YearId INT = SCOPE_IDENTITY();

    INSERT INTO dbo.FeeSchedules (YearId, StageId, FeeType, InstallmentNo, Amount, DueDate)
    SELECT @YearId, s.StageId, f.FeeType, f.InstallmentNo,
           f.BaseAmount + (s.SortOrder - 1) * f.StepAmount,
           CAST(f.DueDate AS DATE)
    FROM dbo.Stages s
    CROSS JOIN (VALUES
        (N'Tuition', 1, 8000, 500, '2026-09-15'),
        (N'Tuition', 2, 8000, 500, '2026-12-15'),
        (N'Tuition', 3, 8000, 500, '2027-03-15'),
        (N'Books',   1, 1500, 100, '2026-10-01'),
        (N'Bus',     1, 3000,   0, '2026-09-15'),
        (N'Bus',     2, 3000,   0, '2027-02-15')
    ) f(FeeType, InstallmentNo, BaseAmount, StepAmount, DueDate);

    INSERT INTO dbo.Students (StudentCode, FullName, Gender, GuardianName, GuardianPhone)
    VALUES
        (N'S1001', N'أحمد محمد علي',          'M', N'محمد علي',          '01000000001'),
        (N'S1002', N'مريم خالد حسن',          'F', N'خالد حسن',          '01000000002'),
        (N'S1003', N'يوسف عمر إبراهيم',       'M', N'عمر إبراهيم',       '01000000003'),
        (N'S1004', N'سلمى طارق سعيد',         'F', N'طارق سعيد',         '01000000004'),
        (N'S1005', N'عمر ياسر عبدالله',       'M', N'ياسر عبدالله',      '01000000005'),
        (N'S1006', N'جنى ياسر عبدالله',       'F', N'ياسر عبدالله',      '01000000005'),
        (N'S1007', N'آدم مصطفى كمال',         'M', N'مصطفى كمال',        '01000000007'),
        (N'S1008', N'ليلى مصطفى كمال',        'F', N'مصطفى كمال',        '01000000007'),
        (N'S1009', N'مالك هشام فؤاد',         'M', N'هشام فؤاد',         '01000000009'),
        (N'S1010', N'فريدة وليد سامي',        'F', N'وليد سامي',         '01000000010'),
        (N'S1011', N'زياد شريف نبيل',         'M', N'شريف نبيل',         '01000000011'),
        (N'S1012', N'حبيبة عادل رمضان',       'F', N'عادل رمضان',        '01000000012'),
        (N'S1013', N'كريم أيمن جمال',         'M', N'أيمن جمال',         '01000000013'),
        (N'S1014', N'نور حسام الدين فتحي',    'F', N'حسام الدين فتحي',   '01000000014'),
        (N'S1015', N'حمزة إيهاب منير',        'M', N'إيهاب منير',        '01000000015'),
        (N'S1016', N'رقية سامح عزت',          'F', N'سامح عزت',          '01000000016'),
        (N'S1017', N'سيف أشرف رشاد',          'M', N'أشرف رشاد',         '01000000017'),
        (N'S1018', N'هنا تامر صلاح',          'F', N'تامر صلاح',         '01000000018'),
        (N'S1019', N'علي محمود زكي',          'M', N'محمود زكي',         '01000000019'),
        (N'S1020', N'ملك عماد شوقي',          'F', N'عماد شوقي',         '01000000020'),
        (N'S1021', N'مازن رامي فاروق',        'M', N'رامي فاروق',        '01000000021'),
        (N'S1022', N'تالين باسم نصر',         'F', N'باسم نصر',          '01000000022'),
        (N'S1023', N'ياسين حازم لطفي',        'M', N'حازم لطفي',         '01000000023'),
        (N'S1024', N'لارا مدحت عاطف',         'F', N'مدحت عاطف',         '01000000024'),
        (N'S1025', N'عبدالرحمن أسامة حلمي',   'M', N'أسامة حلمي',        '01000000025'),
        (N'S1026', N'جودي كريم يسري',         'F', N'كريم يسري',         '01000000026'),
        (N'S1027', N'إياد ماجد صبري',         'M', N'ماجد صبري',         '01000000027'),
        (N'S1028', N'كنزي هاني ثروت',         'F', N'هاني ثروت',         '01000000028'),
        (N'S1029', N'مروان نادر بهاء',        'M', N'نادر بهاء',         '01000000029'),
        (N'S1030', N'سما عصام توفيق',         'F', N'عصام توفيق',        '01000000030');

    SELECT StudentId, ROW_NUMBER() OVER (ORDER BY StudentCode) AS rn
    INTO #S
    FROM dbo.Students;

    DECLARE @ClassCount INT = (SELECT COUNT(*) FROM dbo.Classes);

    INSERT INTO dbo.Enrollments (StudentId, YearId, ClassId)
    SELECT s.StudentId, @YearId, c.ClassId
    FROM #S s
    JOIN (SELECT ClassId, ROW_NUMBER() OVER (ORDER BY ClassId) AS rn FROM dbo.Classes) c
        ON c.rn = ((s.rn - 1) % @ClassCount) + 1;

    UPDATE st
    SET BirthDate = DATEADD(DAY, (s.rn * 37) % 300, DATEADD(YEAR, -(4 + g.SortOrder), CAST('2026-01-01' AS DATE)))
    FROM dbo.Students st
    JOIN #S s             ON s.StudentId = st.StudentId
    JOIN dbo.Enrollments e ON e.StudentId = st.StudentId AND e.YearId = @YearId
    JOIN dbo.Classes c     ON c.ClassId = e.ClassId
    JOIN dbo.Stages g      ON g.StageId = c.StageId;

    INSERT INTO dbo.StudentCharges (EnrollmentId, FeeScheduleId, Amount, Discount)
    SELECT e.EnrollmentId, fs.FeeScheduleId, fs.Amount,
           CASE WHEN fs.FeeType = N'Tuition' AND s.rn IN (7, 8) THEN 500 ELSE 0 END
    FROM dbo.Enrollments e
    JOIN #S s               ON s.StudentId = e.StudentId
    JOIN dbo.Classes c      ON c.ClassId = e.ClassId
    JOIN dbo.FeeSchedules fs ON fs.YearId = e.YearId AND fs.StageId = c.StageId
    WHERE e.YearId = @YearId
      AND (fs.FeeType <> N'Bus' OR s.rn % 3 = 0);

    INSERT INTO dbo.Payments (EnrollmentId, Amount, PaymentDate, ReceiptNo, Method)
    SELECT t.EnrollmentId,
           CASE
               WHEN t.rn BETWEEN 1  AND 10 THEN t.NetTotal
               WHEN t.rn BETWEEN 11 AND 20 THEN ROUND(t.NetTotal * 0.6, -2)
               ELSE t.FirstTuition - 1000
           END,
           DATEADD(DAY, t.rn % 20, CAST('2026-09-05' AS DATE)),
           CONCAT(N'R-2026-', RIGHT(CONCAT(N'0000', t.rn), 4)),
           CASE t.rn % 4
               WHEN 0 THEN N'Cash'
               WHEN 1 THEN N'Card'
               WHEN 2 THEN N'BankTransfer'
               ELSE N'Wallet'
           END
    FROM (
        SELECT e.EnrollmentId, s.rn,
               SUM(sc.Amount - sc.Discount) AS NetTotal,
               SUM(CASE WHEN fs.FeeType = N'Tuition' AND fs.InstallmentNo = 1
                        THEN sc.Amount - sc.Discount ELSE 0 END) AS FirstTuition
        FROM dbo.Enrollments e
        JOIN #S s                ON s.StudentId = e.StudentId
        JOIN dbo.StudentCharges sc ON sc.EnrollmentId = e.EnrollmentId
        JOIN dbo.FeeSchedules fs   ON fs.FeeScheduleId = sc.FeeScheduleId
        WHERE e.YearId = @YearId
        GROUP BY e.EnrollmentId, s.rn
    ) t
    WHERE t.rn <= 27;

    WITH ordered AS (
        SELECT sc.ChargeId, sc.EnrollmentId,
               sc.Amount - sc.Discount AS Net,
               SUM(sc.Amount - sc.Discount) OVER (
                   PARTITION BY sc.EnrollmentId
                   ORDER BY fs.DueDate, fs.InstallmentNo, sc.ChargeId
                   ROWS UNBOUNDED PRECEDING
               ) - (sc.Amount - sc.Discount) AS PrevCum
        FROM dbo.StudentCharges sc
        JOIN dbo.FeeSchedules fs ON fs.FeeScheduleId = sc.FeeScheduleId
    )
    INSERT INTO dbo.PaymentAllocations (PaymentId, ChargeId, Amount)
    SELECT p.PaymentId, o.ChargeId,
           CASE WHEN p.Amount - o.PrevCum >= o.Net THEN o.Net ELSE p.Amount - o.PrevCum END
    FROM ordered o
    JOIN dbo.Payments p ON p.EnrollmentId = o.EnrollmentId
    WHERE p.Amount > o.PrevCum
      AND o.Net > 0;

    DECLARE @TransferredId INT = (SELECT StudentId FROM #S WHERE rn = 3);

    UPDATE dbo.Students
    SET Status = N'Transferred'
    WHERE StudentId = @TransferredId;

    INSERT INTO dbo.Transfers (StudentId, TransferDate, ToSchool, Reason, ClearanceNo)
    VALUES (@TransferredId, '2026-10-20', N'مدارس المستقبل الدولية', N'انتقال محل السكن', N'CL-2026-0001');

    COMMIT TRANSACTION;

    DROP TABLE #S;

    PRINT 'Seed data inserted successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
