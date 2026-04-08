WITH total_revenues AS (
    SELECT 
        o.customer_id,
        SUM(oi.line_revenue) AS total_revenue,
        MIN(o.order_date) AS first_paid_order
    FROM orders o
    JOIN order_items oi
    ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY o.customer_id
), 
ltv_by_channel AS (
    SELECT
        c.channel,
        COUNT(DISTINCT tr.customer_id) AS customers_cnt,
        SUM(tr.total_revenue) AS total_revenue_sum,
        AVG(tr.total_revenue) AS avg_ltv 
    FROM total_revenues tr
    JOIN customers c
    ON tr.customer_id = c.customer_id
    GROUP BY c.channel
),
cac_by_channel AS (
    SELECT 
        sbd.channel,
        SUM(sbd.total_spend) / NULLIF(SUM(COALESCE(npc.new_paying_customers, 0)), 0) AS CAC
    FROM (
        SELECT
            date,
            channel,
            SUM(spend) AS total_spend
        FROM marketing_daily
        GROUP BY date, channel
    ) AS sbd
    LEFT JOIN (
        SELECT 
            first_paid_date AS date,
            channel,
            COUNT(customer_id) AS new_paying_customers
        FROM (
            SELECT
                o.customer_id,
                MIN(o.order_date) AS first_paid_date,
                c.channel
            FROM orders o
            JOIN customers c   
                ON o.customer_id = c.customer_id
            WHERE o.status = 'paid'
            GROUP BY c.channel, o.customer_id ) AS fppc 
    GROUP BY first_paid_date, channel 
    ) AS npc
    ON sbd.date = npc.date
    AND sbd.channel = npc.channel  
    GROUP BY sbd.channel
),
cohort_by_customer AS (
    SELECT
        o.customer_id,
        c.channel,
        MIN(DATE_TRUNC('month', o.order_date)) AS cohort_month
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.status = 'paid'
    GROUP BY o.customer_id, c.channel
),
revenue_by_customer_month AS (
    SELECT
        o.customer_id,
        c.channel,
        cbc.cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month,
        date_diff('month', cbc.cohort_month, DATE_TRUNC ('month', o.order_date)) AS month_index,
        SUM(oi.line_revenue) AS revenue_in_month
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN cohort_by_customer cbc
        ON o.customer_id = cbc.customer_id
        AND c.channel = cbc.channel
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'paid'
    GROUP BY o.customer_id, c.channel, cbc.cohort_month, order_month
),
cumulative_revenue AS (
    SELECT
        customer_id,
        channel,
        cohort_month,
        month_index,
        SUM(revenue_in_month) OVER (PARTITION BY customer_id, channel, cohort_month ORDER BY month_index) AS cumulative_revenue
    FROM revenue_by_customer_month
),
payback_by_customer AS (
    SELECT
        cr.customer_id,
        cr.channel,
        MIN(cr.month_index) AS payback_month
    FROM cumulative_revenue cr
    JOIN cac_by_channel cbc
    ON cr.channel = cbc.channel
    WHERE cr.cumulative_revenue >= cbc.CAC 
    GROUP BY cr.customer_id, cr.channel
),
payback_by_channel AS (
    SELECT
        cbc.channel,
        COUNT(cbc.customer_id) AS customers_cnt,
        AVG(pbc.payback_month) AS avg_payback_month,
        COUNT(pbc.customer_id) AS paid_back_cnt,
        COUNT(DISTINCT pbc.customer_id) / NULLIF(COUNT(DISTINCT cbc.customer_id), 0) AS payback_rate
    FROM cohort_by_customer cbc
    LEFT JOIN payback_by_customer pbc
    ON pbc.customer_id = cbc.customer_id
    AND pbc.channel = cbc.channel
    GROUP BY cbc.channel
),
revenue_3m_by_customer AS (
    SELECT
        customer_id,
        channel,
        SUM(revenue_in_month) AS revenue_3m
    FROM revenue_by_customer_month
    WHERE month_index <= 2
    GROUP BY customer_id, channel
),
revenue_3m_by_channel AS (
    SELECT
        channel,
        AVG(revenue_3m) AS avg_revenue_3m
    FROM revenue_3m_by_customer
    GROUP BY channel    
)
SELECT
    cbc.channel,
    pbch.customers_cnt,
    ROUND(lbc.avg_ltv, 2) AS avg_ltv,
    ROUND(cbc.CAC, 2) AS CAC,
    ROUND(lbc.avg_ltv / NULLIF(cbc.CAC, 0), 2) AS ltv_cac_ratio,
    ROUND(pbch.avg_payback_month, 1) AS avg_payback_month,
    ROUND(pbch.payback_rate, 2) AS payback_rate,
    ROUND(r3m.avg_revenue_3m, 2) AS avg_revenue_3m
FROM cac_by_channel cbc
LEFT JOIN ltv_by_channel lbc
ON cbc.channel = lbc.channel
LEFT JOIN payback_by_channel pbch
ON cbc.channel = pbch.channel
LEFT JOIN revenue_3m_by_channel r3m
ON cbc.channel = r3m.channel
ORDER BY ltv_cac_ratio;
