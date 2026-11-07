DELETE FROM mart.f_customer_retention
WHERE period_name = 'week'
  AND period_id IN (
      SELECT DISTINCT EXTRACT(WEEK FROM dc.date_actual)::int
      FROM mart.f_sales f
      JOIN mart.d_calendar dc ON f.date_id = dc.date_id
  );

INSERT INTO mart.f_customer_retention (
    new_customers_count,
    returning_customers_count,
    refunded_customer_count,
    period_name,
    period_id,
    item_id,
    new_customers_revenue,
    returning_customers_revenue,
    customers_refunded
)
WITH customer_week AS (
    SELECT
        EXTRACT(WEEK FROM dc.date_actual)::int AS period_id,
        f.customer_id,
        COUNT(*) AS orders_count
    FROM mart.f_sales f
    JOIN mart.d_calendar dc ON f.date_id = dc.date_id
    GROUP BY 1, 2
),
customer_item_week AS (
    SELECT
        cw.period_id,
        f.item_id,
        f.customer_id,
        cw.orders_count,
        SUM(f.payment_amount) AS revenue,
        BOOL_OR(f.status = 'refunded') AS has_refund
    FROM mart.f_sales f
    JOIN mart.d_calendar dc ON f.date_id = dc.date_id
    JOIN customer_week cw
      ON cw.period_id = EXTRACT(WEEK FROM dc.date_actual)::int
     AND cw.customer_id = f.customer_id
    GROUP BY 1, 2, 3, 4
)
SELECT
    COUNT(*) FILTER (WHERE orders_count = 1),
    COUNT(*) FILTER (WHERE orders_count > 1),
    COUNT(*) FILTER (WHERE has_refund),
    'week',
    period_id,
    item_id,
    COALESCE(SUM(revenue) FILTER (WHERE orders_count = 1), 0),
    COALESCE(SUM(revenue) FILTER (WHERE orders_count > 1), 0),
    COUNT(*) FILTER (WHERE has_refund)
FROM customer_item_week
GROUP BY period_id, item_id;
