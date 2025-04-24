# Parking Lot Management System – SQL Project

This project is a **relational database design and implementation** for managing a parking lot system. Built entirely using SQL, it demonstrates normalization, entity relationships, constraints, and essential CRUD functionalities for tracking customers, vehicles, parking spots, and their usage over time.

---

## Project Overview

The Parking Lot Management System allows administrators to:
- Register and manage customers
- Track vehicles and their assigned parking spots
- Monitor parking lot capacities
- Log transactions (vehicle entries and exits)
- Maintain real-time status of parking spots (Occupied / Not Occupied)

---

##  Database Schema

The system consists of the following entities:

### 1. `ParkingLot`
- Represents different parking lots
- **Attributes**: `ParkingLotID`, `LotName`, `Location`, `Capacity`

### 2. `Customer`
- Stores user information
- **Attributes**: `CustomerID`, `FirstName`, `LastName`, `Phone`, `Email`

### 3. `Vehicle`
- Represents registered vehicles
- Linked to both customers and parking spots
- **Attributes**: `VehicleID`, `LicensePlate`, `SpotID`, `CustomerID`

### 4. `ParkingSpot`
- Tracks individual parking spots
- Linked to a `ParkingLot`
- Status indicator (`PStatus`) tracks if the spot is occupied
- **Attributes**: `SpotID`, `ParkingLotID`, `SpotNumber`, `PStatus`, `VehicleID`

### 5. `Transactions`
- Logs entry and exit of vehicles with timestamps and payment
- **Attributes**: `TransactionID`, `VehicleID`, `SpotID`, `EntryTime`, `ExitTime`, `Amount`

## Constraints & Integrity
- Foreign key relationships maintain referential integrity
- `ON DELETE CASCADE` ensures dependent records are cleaned up
- Parking spot status updates dynamically based on vehicle entry/exit

---

## File Structure

- `ParkingLotManagementSystem.sql`: Full DDL script to set up and initialize the database

---

## Concepts Demonstrated
- Relational database design
- Data normalization
- Use of primary and foreign keys
- Cascading updates and deletes
- Basic status management logic using SQL
