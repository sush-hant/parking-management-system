DROP DATABASE IF EXISTS ParkingLot_Group2;
CREATE DATABASE ParkingLot_Group2;
USE ParkingLot_Group2;
SHOW TABLES;

-- --------------TABLES-----------------
DROP TABLE IF EXISTS ParkingLot;
CREATE TABLE IF NOT EXISTS ParkingLot(
	ParkingLotID INT PRIMARY KEY AUTO_INCREMENT,
    LotName VARCHAR(25),
    Location VARCHAR(25),
    Capacity INT
);

DROP TABLE IF EXISTS Customer;
CREATE TABLE IF NOT EXISTS Customer (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Phone VARCHAR(15),
    Email VARCHAR(255)
);


DROP TABLE IF EXISTS Vehicle;
CREATE TABLE IF NOT EXISTS Vehicle (
    VehicleID INT PRIMARY KEY AUTO_INCREMENT,
    LicensePlate VARCHAR(20),
    SpotID INT,
    CustomerID INT
);

DROP TABLE IF EXISTS ParkingSpot;
CREATE TABLE IF NOT EXISTS ParkingSpot (
    SpotID INT PRIMARY KEY AUTO_INCREMENT,
    ParkingLotID INT,
    SpotNumber VARCHAR(10),
    PStatus VARCHAR(15) DEFAULT 'N-O',
    VehicleID INT DEFAULT NULL,
    FOREIGN KEY (ParkingLotID) REFERENCES ParkingLot(ParkingLotID)
    
);
ALTER TABLE Vehicle
ADD CONSTRAINT FOREIGN KEY (SpotID) REFERENCES ParkingSpot(SpotID) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE Vehicle 
ADD CONSTRAINT FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ParkingSpot 
ADD CONSTRAINT FOREIGN KEY (VehicleID) REFERENCES Vehicle(VehicleID) ON UPDATE CASCADE ON DELETE CASCADE ;


DROP TABLE IF EXISTS Transactions;
CREATE TABLE IF NOT EXISTS Transactions (
    TransactionID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    VehicleID INT,
    SpotID INT,
    TDateTime DATETIME DEFAULT NOW(),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (VehicleID) REFERENCES Vehicle(VehicleID)  ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (SpotID) REFERENCES ParkingSpot(SpotID)  ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Reservation;
CREATE TABLE IF NOT EXISTS Reservation (
    ReservationID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    ParkingLotID INT,
    SpotID INT,
    ReservationTime DATETIME DEFAULT NOW(),
    CheckInTime DATETIME,
    CheckOutTime DATETIME,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ParkingLotID) REFERENCES ParkingLot(ParkingLotID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (SpotID) REFERENCES ParkingSpot(SpotID) ON DELETE CASCADE ON UPDATE CASCADE
);



DROP TABLE IF EXISTS PaymentTable;
CREATE TABLE IF NOT EXISTS PaymentTable (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    TransactionID INT,
    RTransactionID INT,
    PaymentTime DATETIME DEFAULT NOW(),
    PaymentAmount DECIMAL(10),
    PaymentType VARCHAR(20),
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)  ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (RTransactionID) REFERENCES Reservation(ReservationID)  ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Employee;
CREATE TABLE IF NOT EXISTS Employee (
    EmployeeID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    EPosition VARCHAR(50),
    Phone VARCHAR(15),
    Email VARCHAR(255),
    ParkingID INT,
    FOREIGN KEY (ParkingID) REFERENCES ParkingLot(ParkingLotID)
);


DROP TABLE IF EXISTS EmployeeShift;
CREATE TABLE IF NOT EXISTS EmployeeShift (
    ShiftID INT PRIMARY KEY AUTO_INCREMENT,
    EmployeeID INT,
    ShiftDate DATE,
    StartTime TIME,
    EndTime TIME,
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

DROP TABLE IF EXISTS Feedback;
CREATE TABLE IF NOT EXISTS Feedback (
    FeedbackID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    FeedbackText TEXT,
    Rating INT,
    SubmissionTime DATETIME DEFAULT NOW(),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);


DROP TABLE IF EXISTS EntryRecords;
CREATE TABLE IF NOT EXISTS EntryRecords(
	
    EntryRecordID INT AUTO_INCREMENT PRIMARY KEY,
    TransactionID INT,
    EntryTime DATETIME DEFAULT NOW(),
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS ExitRecords;
CREATE TABLE IF NOT EXISTS ExitRecords(
	
    ExitRecordID INT AUTO_INCREMENT PRIMARY KEY,
    TransactionID INT,
    ExitTime DATETIME DEFAULT NOW(),
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON DELETE CASCADE ON UPDATE CASCADE

); 
 
-- --------------------- FUNCTIONS ------------------------

/* THIS FUNCTION IS USED TO RETRIVE THE FIRST BLANK OR AVALIABLE SPOT IN THE GIVEN PARKING LOT BY THE USER. 
*/

DROP FUNCTION IF EXISTS GetParkingSpot;
DELIMITER \\
CREATE FUNCTION GetParkingSpot(LOT VARCHAR(10))
RETURNS INT
DETERMINISTIC
BEGIN 
	DECLARE SpotId INT;
    SELECT  ParkingSpot.SpotID INTO SpotId
    FROM ParkingSpot
    WHERE Pstatus = 'N-O'  AND ParkingSPot.ParkingLotID = (SELECT ParkingLotID FROM ParkingLot WHERE LotName = LOT)
	LIMIT 1;
    
    RETURN SpotId;
END \\


/* THIS FUNCTOIN IS USED TO GET THE LATEST CUSTOMER WHICH IS THEN ASSOCIATED WITH A VEHICLE*/
DROP FUNCTION IF EXISTS GiveLatestCustomer;
DELIMITER \\
CREATE FUNCTION GiveLatestCustomer()
RETURNS INT
DETERMINISTIC
BEGIN 
	DECLARE CustomerID INT;
    SELECT customer.CustomerID INTO CustomerID
    FROM customer
    ORDER BY customer.CustomerID DESC
	LIMIT 1;
    
    RETURN CustomerID;
END \\

/* THIS FUNCTIO IS USED TO GET THE CUSTOMER ASSOCIATE WITH THE GIVEN VEHICLE */
DROP FUNCTION IF EXISTS GetCustomerViaVehicle;
DELIMITER \\
CREATE FUNCTION GetCustomerViaVehicle(License VARCHAR(20))
RETURNS INT
DETERMINISTIC 
BEGIN 
	DECLARE VehicleID INT;
	SELECT Vehicle.VehicleID INTO VehicleID FROM Vehicle 
    WHERE Vehicle.LicensePlate = License;
    
    RETURN VehicleID;
END\\

-- -------------------- PROCEDURES -----------

/* THIS PROCEDURE ADDS A NEW ROW IN VEHICLE TABLE , IN HERE WE'VE USED TWO USER DEFINED FUNCTION 
	1. GetParkingSpot THIS IS USED TO GET THE FIRST FREE PARKING SPOT OF THE GIVEN PARKING LOT
    2. GiveLatestCustomer THIS IS USED TO FETCH THE LATEST CUSTOMER 
*/

DROP PROCEDURE IF EXISTS AddVehicle;
DELIMITER \\
CREATE PROCEDURE AddVehicle( IN LicensePlate VARCHAR(10), IN LOT VARCHAR(10)) 
BEGIN
	DECLARE SpotID INT;
    DECLARE CustomerID INT;
    SET SpotID = GetParkingSpot(LOT);
    SET CustomerID = GiveLatestCustomer();
    
    
    INSERT INTO Vehicle VALUES(NULL, LicensePlate, SpotID, CustomerID);
    
END\\


/* THIS PROCEDURE ADDS A NEW ROW IN RESERVATION TABLE.
	LOT NAME, CHECKIN AND CHECKOUT TIME ARE THE ARGUEMENTS REQUIRED.
    THE EXIT PART OF A RESERVED CAR IS NOT BEEN IMPLEMENT AS IT WILL REQUIRE SCHEDULING CONCEPTS
*/

DROP PROCEDURE IF EXISTS AddReservation;
DELIMITER \\
CREATE PROCEDURE AddReservation(IN Lot VARCHAR(10), IN checkIn DATETIME, IN checkOut DATETIME)
BEGIN 
	DECLARE spot INT;
    DECLARE customer INT;
    DECLARE ParkingLot INT;
    SELECT ParkingLotID INTO ParkingLot FROM ParkingLot WHERE Lotname = Lot;
    SELECT  ParkingSpot.SpotID INTO Spot
				FROM ParkingSpot
				WHERE ParkingSpot.Pstatus = 'N-O' and ParkingSpot.ParkingLotID = ParkingLot
				LIMIT 1;
	SET customer = GiveLatestCustomer();
	INSERT INTO Reservation (CustomerID, ParkingLotID,SpotID, CheckInTime,CheckOutTime)
    VALUES(customer,ParkingLot, spot, checkIn, checkOut);
END \\

/* THIS PROCEDURE IS USED TO ADD A NEW EXIT RECORD IN THE TABLE
	IN HERE WE GIVE LICENSE PLATE AS A ARGUMENT, DEPICTING A VEHICLE MOVING OUT OF A LOT
*/

DROP PROCEDURE IF EXISTS AddExitRecord;
DELIMITER \\
CREATE PROCEDURE AddExitRecord(IN License VARCHAR(20))
BEGIN
	
	DECLARE TransactionID INT;
    DECLARE VehicleID INT;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;
    SET VehicleID = GetCustomerViaVehicle(License);
    
    SELECT Transactions.TransactionID INTO TransactionID FROM Transactions
    WHERE Transactions.VehicleID = VehicleID;
    
    INSERT INTO ExitRecords(TransactionID) VALUE(TransactionID);
    COMMIT;
END \\


-- -------------TRIGGGERS --------------

/* THIS TRIGGER IS USED TO ADD PARKING SPOT'S IN THE PARKING SPOT TABLE 
*/

DROP TRIGGER IF EXISTS AddParkingSpots;
DELIMITER //
CREATE TRIGGER AddParkingSpots
AFTER INSERT ON ParkingLot
FOR EACH ROW
BEGIN
    DECLARE counter INT DEFAULT 1 ;

    WHILE counter <  NEW. Capacity + 1 DO
        
        INSERT INTO ParkingSpot(ParkingLotID, SpotNumber) VALUES(NEW.ParkingLotID, counter);
        SET counter = counter + 1;
    END WHILE;
END//


/* THIS TRIGGER IS USED TO UPDATE THE PARKING SPOT AS OCCUPIED HERE 'O'
*/
DROP TRIGGER IF EXISTS UpdateParkingSpot;
DELIMITER \\
CREATE TRIGGER UpdateParkingSpot
AFTER INSERT ON Vehicle 
FOR EACH ROW
BEGIN
	UPDATE ParkingSpot
    SET VehicleID = NEW.VehicleID, Pstatus = 'O'
    WHERE SpotID = NEW.SpotID;
END\\

/* 
THIS TRIGGER IS USED TO ADD A NEW ROW IN TRANSACTION TABLE AS SOON AS A PARKINGSPOT IS UPDATED IN THE TABLE
*/

DROP TRIGGER IF EXISTS AddTransactions;
DELIMITER \\
CREATE TRIGGER  AddTransactions
AFTER UPDATE ON ParkingSpot
FOR EACH ROW
BEGIN
		DECLARE CustomerID INT;
		DECLARE SpotID INT;
		DECLARE VehicleID INT;
		SET CustomerID = GiveLatestCustomer();
		SET SpotID = NEW.SpotID;
		SET VehicleID = NEW.VehicleID;
	IF NEW.Pstatus = 'O' THEN

		
		INSERT INTO Transactions(CustomerID ,VehicleID,SpotID) VALUES(CustomerID, VehicleID, SpotID);
    END IF;
END\\


/* 
THIS TRIGGER IS USED TO ADD A NEW ENTRY IN RECORD TABLE
*/
DROP TRIGGER IF EXISTS AddEntryRecored;
DELIMITER \\
CREATE TRIGGER AddEntryRecored
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN 
	DECLARE TransactionID INT;
	SET TransactionID = NEW.TransactionID;
    INSERT INTO EntryRecords(TransactionID) VALUE(TransactionID);
    
END\\


/* 
THIS TRIGGER IS USED ONCE A RESERVATION IS ADDED IN THE RESERVATION TABLE. IT WILL ADD A NEW ROW IN PAYMENT TABLE
*/
DROP TRIGGER IF EXISTS AddPaymentReservation;
DELIMITER \\
CREATE TRIGGER AddPaymentReservation
AFTER INSERT ON Reservation
FOR EACH ROW
BEGIN 
	DECLARE amount DECIMAL(10);
    DECLARE totalTime DECIMAL(10, 2);
    SET totalTime = (TIME_TO_SEC(TIMEDIFF( NEW.CheckOutTime, NEW.CheckInTime))/3600);
    SET amount = totalTime*5.0;
	INSERT INTO PaymentTable(TransactionID, RTransactionID, PaymentAmount, PaymentType) VALUES (NULL,NEW.ReservationID, amount, "reservation");
END \\


/* 
THIS TRIGGER IS USED TO ADD A PAYMENT ROW WHEN A VEHICLE IS EXITED.
THIS IS DIFFERENT THAN THE TRIGGER IS USED FOR RESERVATION TABLE
*/

DROP TRIGGER IF EXISTS AddPayment;
DELIMITER \\
CREATE TRIGGER AddPayment
AFTER INSERT ON ExitRecords
FOR EACH ROW
BEGIN 
	DECLARE amount DECIMAL(10);
    DECLARE totalTime DECIMAL(10, 2);
    DECLARE inTime DATETIME;
    SELECT EntryTime INTO inTime FROM EntryRecords
    WHERE EntryRecords.TransactionID = NEW.TransactionID;
    SET totalTime = (TIME_TO_SEC(TIMEDIFF( NEW.ExitTime, inTime))/3600);
    SET amount = totalTime*5.0;
    
	INSERT INTO PaymentTable(TransactionID, RTransactionID, PaymentAmount, PaymentType) VALUES (NEW.TransactionID,NULL, amount, "drive-in");
    
END \\


/* 
THIS TRIGGER IS USED TO UPDATE THE PARKINGPOT ONCE THE VEHICLE IS EXITED 
*/

DROP TRIGGER IF EXISTS UpdateSpotAfterExit;
DELIMITER \\
CREATE TRIGGER UpdateSpotAfterExit
AFTER INSERT ON ExitRecords
FOR EACH ROW
BEGIN 
	UPDATE ParkingSPot
    SET PStatus = 'N-O' , VehicleID = NULL
    WHERE VehicleId = (SELECT VehicleID FROM Transactions WHERE TransactionID = NEW.TransactionID);
END\\

 
 
 
 -- INSERTIONS & CALLING STORED PROCECURES ----------------
 -- INSERTING ROWS IN PARKING LOT TABLE
INSERT INTO ParkingLot(LotName, Location, Capacity) VALUE("Lot A", "UT Dallas", 10);
INSERT INTO ParkingLot(LotName, Location, Capacity) VALUE("Lot B", "UT Dallas", 15);
INSERT INTO ParkingLot(LotName, Location, Capacity) VALUE("Lot C", "UT Dallas", 10);
INSERT INTO ParkingLot(LotName, Location, Capacity) VALUE("Lot D", "UT Dallas", 20);
INSERT INTO ParkingLot(LotName, Location, Capacity) VALUE("Lot E", "UT Dallas", 25);
 
 
 
-- USE THIS TO ADD A NEW CUSTOMER AND CORRESPONDING VEHICLE IN THEIR RESPECTIVETABLES, CHECK PROCEDURE SECTION FOR THE CODE
INSERT INTO Customer VALUE(NULL, "Larry", "Page", 6286189790, "lxp628618@utdallas.edu");
CALL AddVehicle("AJA 123", "Lot A" );


INSERT INTO Customer VALUE(NULL, "Mark", "Zuck", 6186286186, "mxz618628@utdallas.edu");
CALL Addvehicle("BMB 333", "Lot A");


INSERT INTO Customer VALUE(NULL, "Elon", "Musk", 5175618622, "exm517561@utdallas.edu");
CALL Addvehicle("RAA 768", "Lot B");

INSERT INTO Customer VALUE(NULL, "Steve", "Jobs", 5437525612, "sxj543752@utdallas.edu");
CALL Addvehicle("HJI 454", "Lot C");


INSERT INTO Customer VALUE(NULL, "Aurora", "Reynolds", 6816716716, "axr681671@utdallas.edu"); 
CALL Addvehicle("ABC 456", "Lot A");

INSERT INTO Customer VALUE(NULL, "Malik", "Thompson", 9819778290, "mxt981977@utdallas.edu");
CALL Addvehicle("XYZ 789", "Lot B");


INSERT INTO Customer VALUE(NULL, "Zoe", "Hernandez", 7816725711, "zxh781672@utdallas.edu");
CALL Addvehicle("MNO 123", "Lot C");


INSERT INTO Customer VALUE(NULL, "Caleb", "Mitchell", 9617624641, "cxm961762@utdallas.edu"); 
CALL Addvehicle("QRS 890", "Lot C");

INSERT INTO Customer VALUE(NULL, "Isabella", "Chang", 8917561572, "ixc891756@utdallas.edu"); 
CALL Addvehicle("DEF 456", "Lot B");

INSERT INTO Customer VALUE(NULL, "Olivia",  "Rodriguez", 6381680189, "oxr638168@utdallas.edu"); 
CALL Addvehicle("UVW 789", "Lot A");


INSERT INTO Customer VALUE(NULL, "Noah", "Foster", 9178927810, "nxf917892@utdallas.edu"); 
CALL Addvehicle("JKL 123", "Lot B");

INSERT INTO Customer VALUE(NULL, "Maya", "Gupta", 8917561572, "ixc891756@utdallas.edu"); 
CALL Addvehicle("HIJ 890", "Lot A");

-- USE THIS TO ADD A NEW ROW IN RESERVATION TABLE, CHECK PROCEDURE SECTION FOR THE CODE
INSERT INTO Customer VALUE(NULL, "Xavier", "Patel", 8617514629, "xxp861751@utdallas.edu"); 
CALL AddReservation('Lot A', '2023-12-08 13:25:00', '2023-12-08 14:25:00');

INSERT INTO Customer VALUE(NULL, "Liam", "Turner", 6816691762, "lxt681669@utdallas.edu"); 
CALL AddReservation('Lot B', '2023-12-09 16:20:00', '2023-12-09 18:25:00');

INSERT INTO Customer VALUE(NULL, "Sophia", "Nguyen", 9718635671, "sxn971863@utdallas.edu"); 
CALL AddReservation('Lot C', '2023-12-10 09:45:00', '2023-12-10 11:20:00');

INSERT INTO Customer VALUE(NULL, "Ethan", "Parker", 5170816729, "exp517081@utdallas.edu"); 
CALL AddReservation('Lot A', '2023-12-12 14:15:00', '2023-12-12 16:30:00');

INSERT INTO Customer VALUE(NULL, "Serenity", "Morgan", 9517654681, "sxm951765@utdallas.edu"); 
CALL AddReservation('Lot B', '2023-12-20 12:00:00', '2023-12-20 14:10:00');

INSERT INTO Customer VALUE(NULL, "Felix", "Turner", 9618637810, "fxt961863@utdallas.edu"); 
CALL AddReservation('Lot C', '2023-12-25 08:30:00', '2023-12-25 10:40:00');

 -- Inserting data into the Employee table

INSERT INTO Employee (FirstName, LastName, EPosition, Phone, Email, ParkingID)
VALUES 
    ('John', 'Doe', 'Attendant', '555-1234', 'jxa123456@utdallas.edu', 3),
    ('Jane', 'Smith', 'Security', '555-5678', 'jxx654321@utdallas.edu',4),
    ('Mike', 'Johnson', 'Manager', '555-9876', 'mxj234567@utdallas.edu', 3),
    ('Emily', 'Williams', 'Attendant', '555-4321', 'exw654321@utdallas.edu', 3),
    ('Chris', 'Taylor', 'Attendant', '555-8765', 'cxt987654@utdallas.edu', 4),
    ('Sara', 'Anderson', 'Security', '555-2345', 'sxa876543@utdallas.edu', 5),
    ('David', 'Clark', 'Manager', '555-8765', 'dxc567890@utdallas.edu', 4),
    ('Lisa', 'Miller', 'Attendant', '555-3456', 'lxm098765@utdallas.edu', 5),
    ('Michael', 'Moore', 'Attendant', '555-7890', 'mxm123456@utdallas.edu', 4),
    ('Amy', 'Brown', 'Security', '555-5678', 'axb234567@utdallas.edu', 5);

-- INSERTING INTO EMPLOYEESHFIT TABLE
INSERT INTO EmployeeShift (EmployeeID, ShiftDate, StartTime, EndTime)
VALUES 
    (1, '2023-12-08', '08:00:00', '16:00:00'),
    (2, '2023-12-08', '12:00:00', '20:00:00'),
    (3, '2023-12-08', '09:00:00', '17:00:00'),
    (4, '2023-12-08', '14:00:00', '22:00:00'),
    (5, '2023-12-08', '10:00:00', '18:00:00'),
    (6, '2023-12-08', '11:00:00', '19:00:00'),
    (7, '2023-12-08', '13:00:00', '21:00:00'),
    (8, '2023-12-08', '15:00:00', '23:00:00'),
    (9, '2023-12-08', '07:00:00', '15:00:00'),
    (10, '2023-12-08', '16:00:00', '00:00:00');

 
 
 -- INSERTING DATA INTO THE FEEDBACK TABLES
INSERT INTO Feedback (CustomerID, FeedbackText, Rating, SubmissionTime)
VALUES 
    ( 13, 'Great service! Very satisfied.', 5, '2023-12-08 10:30:00'),
    ( 14, 'Could improve cleanliness.', 3, '2023-12-08 11:15:00'),
    ( 15, 'Prompt response and helpful staff.', 4, '2023-12-08 12:00:00'),
    ( 16, 'Excellent experience overall.', 5, '2023-12-08 13:45:00'),
    ( 17, 'Issues with parking space availability.', 2, '2023-12-08 14:30:00'),
    ( 18, 'Friendly staff but slow service.', 3, '2023-12-08 15:15:00');

 
 
 -- USE THIS TO ADD A NEW ROW IN EXIT TABLE LICENSE PLATE IS GIVEN AS PARAMETER, CHECK PROCEDURE SECTION FOR THE CODE
CALL AddExitRecord("AJA 123");
CALL AddExitRecord("BMB 333");
CALL AddExitRecord("RAA 768");
CALL AddExitRecord("HJI 454");
CALL AddExitRecord("ABC 456");
CALL AddExitRecord("XYZ 789");
CALL AddExitRecord("MNO 123");
CALL AddExitRecord("QRS 890");
CALL AddExitRecord("DEF 456");
CALL AddExitRecord("UVW 789");
CALL AddExitRecord("JKL 123");
CALL AddExitRecord("HIJ 890");


 
 
-- Retrieve all information--

SELECT * FROM ParkingLot;
SELECT * FROM ParkingSpot;
SELECT * FROM Customer;
SELECT * FROM Vehicle;
SELECT * FROM EntryRecords;
SELECT * FROM Transactions;
SELECT * FROM ExitRecords;
select * from paymentTable;
select * from reservation;
select * from  EmployeeShift;
select * from  Employee;

-- Find the license plates of vehicles parked in a specific parking lot --

SELECT 
    Vehicle.LicensePlate, 
    ParkingSpot.SpotNumber
FROM 
    Vehicle
JOIN 
    ParkingSpot ON Vehicle.VehicleID = ParkingSpot.VehicleID
WHERE 
    ParkingSpot.ParkingLotID = 3;

-- List all employees and their shifts --

SELECT 
    Employee.FirstName, 
    Employee.LastName, 
    EmployeeShift.ShiftDate, 
    EmployeeShift.StartTime, 
    EmployeeShift.EndTime
FROM 
    Employee
JOIN 
    EmployeeShift ON Employee.EmployeeID = EmployeeShift.EmployeeID;

 
-- Retrieve transaction details for a specific customer --

SELECT 
    Transactions.*, 
    ParkingSpot.SpotNumber
FROM 
    Transactions
JOIN 
    ParkingSpot ON Transactions.SpotID = ParkingSpot.SpotID
WHERE 
    Transactions.CustomerID = 7;
 # taking customerid 7 as an example
 
-- Get the total amount paid by customers for transactions --

SELECT 
    Customer.FirstName, 
    Customer.LastName, 
    SUM(PaymentTable.PaymentAmount) AS TotalAmountPaid
FROM 
    Customer
JOIN 
    Transactions ON Customer.CustomerID = Transactions.CustomerID
JOIN 
    PaymentTable ON Transactions.TransactionID = PaymentTable.TransactionID
GROUP BY 
    Customer.CustomerID, Customer.FirstName, Customer.LastName;

-- Find available parking spots in a specific parking lot --

SELECT 
    SpotNumber
FROM 
    ParkingSpot
WHERE 
    ParkingLotID = 3 AND PStatus = 'O';

 
-- Retrieve Entry and Exit Records for a Transaction --
SELECT 
    *
FROM 
    EntryRecords
JOIN 
    ExitRecords ON EntryRecords.TransactionID = ExitRecords.TransactionID
WHERE 
    EntryRecords.TransactionID = 3;

 
-- ------------ complex queries -----------
 
-- Retrieve the names of customers who have made transactions during the last month, along with the total amount they have paid.
 
SELECT 
    C.FirstName, 
    C.LastName, 
    SUM(PT.PaymentAmount) AS TotalAmountPaid
FROM 
    Customer C
JOIN 
    Transactions T ON C.CustomerID = T.CustomerID
JOIN 
    ExitRecords ER ON T.TransactionID = ER.TransactionID
JOIN 
    PaymentTable PT ON T.TransactionID = PT.TransactionID
WHERE 
    ER.ExitTime >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
GROUP BY 
    C.CustomerID, C.FirstName, C.LastName;


 
-- Find the parking spots that are currently occupied and display the vehicle information along with the parking spot details.
 
SELECT 
    PS.SpotID, 
    PS.SpotNumber, 
    V.LicensePlate, 
    PStatus
FROM 
    ParkingSpot PS
JOIN 
    Vehicle V ON PS.VehicleID = V.VehicleID
WHERE 
    PStatus = 'O';

 
-- Find the average rating and the count of feedback received for each parking lot. Display the results in descending order of average rating.
 
SELECT 
    LotName AS ParkingLotName, 
    AVG(F.Rating) AS AverageRating, 
    COUNT(F.FeedbackID) AS FeedbackCount
FROM 
    ParkingLot
LEFT JOIN 
    Reservation R ON ParkingLot.ParkingLotID = R.ParkingLotID
LEFT JOIN 
    Feedback F ON R.CustomerID = F.CustomerID
GROUP BY 
    ParkingLot.ParkingLotID, LotName
ORDER BY 
    AverageRating DESC
LIMIT 
    0, 1000;

 
-- Retrieve the top 5 customers who have spent the most on parking, along with the total amount spent by each.
 
SELECT 
    C.CustomerID, 
    C.FirstName, 
    C.LastName, 
    SUM(PT.PaymentAmount) AS TotalAmountSpent
FROM 
    Customer C
JOIN 
    Transactions T ON C.CustomerID = T.CustomerID
JOIN 
    PaymentTable PT ON T.TransactionID = PT.TransactionID
GROUP BY 
    C.CustomerID, C.FirstName, C.LastName
ORDER BY 
    TotalAmountSpent DESC
LIMIT 5;

 
-- Find the parking lots that have the highest and lowest capacities, along with the number of available spots in each.
 
SELECT 
    P.ParkingLotID, 
    lotName, 
    Capacity, 
    COUNT(PS.PStatus) AS AvailableSpots
FROM 
    ParkingLot P
LEFT JOIN 
    ParkingSpot PS ON P.ParkingLotID = PS.ParkingLotID AND PS.PStatus = 'N-O'
GROUP BY 
    P.ParkingLotID, lotName, Capacity
ORDER BY 
    Capacity DESC, AvailableSpots ASC;

 
-- Retrieve the top 3 parking lots with the highest total revenue (sum of amounts paid) for completed transactions in the last three months ---

SELECT 
    P.ParkingLotID, 
    P.LotName AS ParkingLotName, 
    SUM(PT.PaymentAmount) AS TotalRevenue
FROM 
    ParkingLot P
LEFT JOIN 
    ParkingSpot PS ON P.ParkingLotID = PS.ParkingLotID
LEFT JOIN 
    Transactions T ON PS.SpotID = T.SpotID
LEFT JOIN 
    PaymentTable PT ON T.TransactionID = PT.TransactionID
WHERE 
    PT.PaymentTime IS NOT NULL AND PT.PaymentTime >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
GROUP BY 
    P.ParkingLotID, P.LotName
ORDER BY 
    TotalRevenue DESC
LIMIT 3;


 
-- Find the customers who have given feedback with a rating less than 3, along with the details of their feedback and the corresponding parking lot ---
 
SELECT 
    C.FirstName, 
    C.LastName, 
    F.FeedbackText, 
    F.Rating, 
    P.lotName AS ParkingLotName
FROM 
    Customer C
JOIN 
    Feedback F ON C.CustomerID = F.CustomerID
JOIN 
    Reservation R ON C.CustomerID = R.CustomerID
JOIN 
    ParkingLot P ON R.ParkingLotID = P.ParkingLotID
WHERE 
    F.Rating < 3;

 
-- List the employees who have not been assigned any shifts, along with their contact information.
 
SELECT 
    E.FirstName, 
    E.LastName, 
    E.Phone, 
    E.Email
FROM 
    Employee E
LEFT JOIN 
    EmployeeShift ES ON E.EmployeeID = ES.EmployeeID
WHERE 
    ES.EmployeeID IS NULL;

 
-- Identify the parking spots that have been reserved but are currently unoccupied, along with the reservation details.
 
SELECT 
    PS.SpotID, PS.SpotNumber, R.ReservationID, R.ReservationTime
FROM
    ParkingSpot PS
        LEFT JOIN
    Reservation R ON PS.SpotID = R.SpotID
WHERE
    R.CheckInTime IS NULL
        AND R.CheckOutTime IS NULL;
 
-- Retrieve the average number of feedback submissions per month for each parking lot, considering only the last six months.
 
SELECT 
    P.ParkingLotID,
    lotName AS ParkingLotName,
    COUNT(F.FeedbackID) / 6 AS AvgFeedbacksPerMonth
FROM
    ParkingLot P
        LEFT JOIN
    Reservation R ON P.ParkingLotID = R.ParkingLotID
        LEFT JOIN
    Feedback F ON R.CustomerID = F.CustomerID
WHERE
    F.SubmissionTime >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY P.ParkingLotID;
 
-- ---------- Joints ---------- --
 
-- List all transactions with customer and vehicle details  --
SELECT 
    Transactions.TransactionID,
    Transactions.TDateTime,
    Customer.FirstName,
    Customer.LastName,
    Customer.Phone,
    Customer.Email,
    Vehicle.LicensePlate,
    ParkingSpot.SpotNumber
FROM Transactions
JOIN Customer ON Transactions.CustomerID = Customer.CustomerID
JOIN Vehicle ON Transactions.VehicleID = Vehicle.VehicleID
JOIN ParkingSpot ON Transactions.SpotID = ParkingSpot.SpotID;
 

-- Find available parking spots in a specific parking lot --
SELECT 
    ParkingSpot.SpotNumber
FROM ParkingSpot
JOIN ParkingLot ON ParkingSpot.ParkingLotID = ParkingLot.ParkingLotID
WHERE ParkingSpot.PStatus = 'N-O' AND ParkingLot.LotName = 'Lot A';
 

-- List all vehicles and their owners --
SELECT 
    Vehicle.LicensePlate,
    Customer.FirstName,
    Customer.LastName
FROM Vehicle
JOIN Customer ON Vehicle.CustomerID = Customer.CustomerID;
 

-- List all reservations with customer, parking lot, and spot details --
SELECT 
    Reservation.ReservationID,
    Reservation.ReservationTime,
    Reservation.CheckInTime,
    Reservation.CheckOutTime,
    Customer.FirstName,
    Customer.LastName,
    ParkingLot.LotName,
    ParkingSpot.SpotNumber
FROM Reservation
JOIN Customer ON Reservation.CustomerID = Customer.CustomerID
JOIN ParkingLot ON Reservation.ParkingLotID = ParkingLot.ParkingLotID
JOIN ParkingSpot ON Reservation.SpotID = ParkingSpot.SpotID;
 

-- List all payments with transaction details --
SELECT 
    PaymentTable.PaymentID,
    PaymentTable.PaymentTime,
    PaymentTable.PaymentAmount,
    PaymentTable.PaymentType,
    Transactions.TransactionID,
    Transactions.TDateTime,
    Customer.FirstName,
    Customer.LastName,
    Vehicle.LicensePlate,
    ParkingSpot.SpotNumber
FROM PaymentTable
LEFT JOIN Transactions ON PaymentTable.TransactionID = Transactions.TransactionID
LEFT JOIN Customer ON Transactions.CustomerID = Customer.CustomerID
LEFT JOIN Vehicle ON Transactions.VehicleID = Vehicle.VehicleID
LEFT JOIN ParkingSpot ON Transactions.SpotID = ParkingSpot.SpotID;
 

-- List all employees with their assigned parking lots:--
SELECT 
    Employee.EmployeeID,
    Employee.FirstName,
    Employee.LastName,
    Employee.EPosition,
    Employee.Phone,
    Employee.Email,
    ParkingLot.LotName AS AssignedParkingLot
FROM Employee
LEFT JOIN ParkingLot ON Employee.ParkingID = ParkingLot.ParkingLotID;
 

-- SELF JOINS --
-- Self-Join on the Employee table to find employees with the same assigned parking lot --
SELECT 
    e1.EmployeeID AS Employee1ID,
    e1.FirstName AS Employee1FirstName,
    e1.LastName AS Employee1LastName,
    e1.EPosition AS Employee1Position,
    e2.EmployeeID AS Employee2ID,
    e2.FirstName AS Employee2FirstName,
    e2.LastName AS Employee2LastName,
    e2.EPosition AS Employee2Position,
    pl.LotName AS AssignedParkingLot
FROM Employee e1
JOIN Employee e2 ON e1.ParkingID = e2.ParkingID AND e1.EmployeeID <> e2.EmployeeID
JOIN ParkingLot pl ON e1.ParkingID = pl.ParkingLotID
WHERE ParkingLotId = 3;
 

-- Self-Join on the Employee table to find employees with the same position --
SELECT 
    e1.EmployeeID AS Employee1ID,
    e1.FirstName AS Employee1FirstName,
    e1.LastName AS Employee1LastName,
    e1.EPosition AS Employee1Position,
    e2.EmployeeID AS Employee2ID,
    e2.FirstName AS Employee2FirstName,
    e2.LastName AS Employee2LastName,
    e2.EPosition AS Employee2Position
FROM Employee e1
JOIN Employee e2 ON e1.EPosition = e2.EPosition AND e1.EmployeeID <> e2.EmployeeID;

