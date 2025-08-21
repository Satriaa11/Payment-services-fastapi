-- Initialize database for TiketQ services

-- Create user_profiles table for user-service
CREATE TABLE IF NOT EXISTS user_profiles (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    date_of_birth VARCHAR(10),
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- Create users table for auth-service (if not exists)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role VARCHAR(10) DEFAULT 'user' CHECK (role IN ('user', 'admin'))
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create index on role for faster role-based queries
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Connect to the tiketq database
\c tiketq_db;

-- Grant permissions for shared database access
GRANT ALL ON SCHEMA public TO tiketq_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tiketq_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tiketq_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO tiketq_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO tiketq_user;

-- Create PAYMENTS table
CREATE TABLE IF NOT EXISTS payments (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(100),
    midtrans_token VARCHAR(255),
    redirect_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create CUSTOMER_DETAILS table
CREATE TABLE IF NOT EXISTS customer_details (
    payment_id VARCHAR(255) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    billing_address JSONB,
    shipping_address JSONB,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);

-- Create ITEM_DETAILS table
CREATE TABLE IF NOT EXISTS item_details (
    id VARCHAR(255) PRIMARY KEY,
    payment_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    category VARCHAR(100),
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);

-- Create PAYMENT_TRANSACTIONS table
CREATE TABLE IF NOT EXISTS payment_transactions (
    transaction_id VARCHAR(255) PRIMARY KEY,
    payment_id VARCHAR(255) NOT NULL,
    midtrans_transaction_id VARCHAR(255),
    transaction_status VARCHAR(50),
    gross_amount DECIMAL(15,2),
    payment_type VARCHAR(100),
    midtrans_response JSONB,
    transaction_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at);
CREATE INDEX IF NOT EXISTS idx_payments_payment_method ON payments(payment_method);
CREATE INDEX IF NOT EXISTS idx_payments_midtrans_token ON payments(midtrans_token);

CREATE INDEX IF NOT EXISTS idx_customer_details_email ON customer_details(email);
CREATE INDEX IF NOT EXISTS idx_customer_details_payment_id ON customer_details(payment_id);

CREATE INDEX IF NOT EXISTS idx_item_details_payment_id ON item_details(payment_id);
CREATE INDEX IF NOT EXISTS idx_item_details_category ON item_details(category);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_id ON payment_transactions(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_midtrans_id ON payment_transactions(midtrans_transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(transaction_status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_time ON payment_transactions(transaction_time);

-- Add comments for documentation
COMMENT ON TABLE payments IS 'Main payments table storing payment records';
COMMENT ON TABLE customer_details IS 'Customer information for each payment';
COMMENT ON TABLE item_details IS 'Items being paid for in each payment';
COMMENT ON TABLE payment_transactions IS 'Transaction records from Midtrans';

COMMENT ON SCHEMA public IS 'TiketQ shared database schema for all microservices';