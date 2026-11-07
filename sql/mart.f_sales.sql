
DELETE FROM mart.f_sales
WHERE date_id IN (
    SELECT date_id
    FROM mart.d_calendar
    WHERE date_actual = '{{ ds }}'::date
);

INSERT INTO mart.f_sales
    (date_id, item_id, customer_id, city_id, quantity, payment_amount, status)
SELECT
    dc.date_id,
    uol.item_id,
    uol.customer_id,
    uol.city_id,
    uol.quantity,
    CASE
        WHEN COALESCE(uol.status, 'shipped') = 'refunded'
        THEN -ABS(uol.payment_amount)
        ELSE uol.payment_amount
    END,
    COALESCE(uol.status, 'shipped')
FROM staging.user_order_log uol
JOIN mart.d_calendar dc
    ON uol.date_time::date = dc.date_actual
WHERE uol.date_time::date = '{{ ds }}'::date;
