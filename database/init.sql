-- Initialize Sertantai Controls database
-- This script runs once on first PostgreSQL container startup

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- Create schema for ElectricSQL (if needed)
-- ElectricSQL will create its own objects as needed

-- Note: Application tables will be created via Phoenix migrations
