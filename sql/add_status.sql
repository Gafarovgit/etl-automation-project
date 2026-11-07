ALTER TABLE staging.user_order_log
ADD COLUMN status VARCHAR(20) DEFAULT 'shipped';

UPDATE staging.user_order_log
SET status = 'shipped'
WHERE status IS NULL;