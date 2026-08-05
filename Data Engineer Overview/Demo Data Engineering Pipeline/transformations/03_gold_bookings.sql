-- ============================================================
-- GOLD: aggregate into richer daily city-level booking metrics.
-- ============================================================
CREATE OR REFRESH MATERIALIZED VIEW workspace.`03_gold`.gold_bookings
(
  check_in_date        DATE,
  city                 STRING,
  total_bookings       BIGINT,
  confirmed_bookings   BIGINT,
  completed_bookings   BIGINT,
  cancelled_bookings   BIGINT,
  pending_bookings     BIGINT,
  total_nights         BIGINT,
  avg_nights           DECIMAL(19,4),
  total_guests         BIGINT,
  total_revenue        DECIMAL(19,4),
  avg_price_per_night  DECIMAL(19,4),
  distinct_properties  BIGINT,
  first_check_in       STRING,
  last_check_out       STRING
)
AS
SELECT
  check_in                                                 AS check_in_date,
  city,
  COUNT(DISTINCT booking_id)                               AS total_bookings,
  SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END)    AS confirmed_bookings,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END)    AS completed_bookings,
  SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END)    AS cancelled_bookings,
  SUM(CASE WHEN status = 'pending'   THEN 1 ELSE 0 END)    AS pending_bookings,
  SUM(nights_stayed)                                       AS total_nights,
  CAST(AVG(nights_stayed) AS DECIMAL(19,4))                AS avg_nights,
  SUM(guests_count)                                        AS total_guests,
  CAST(SUM(total_amount) AS DECIMAL(19,4))                 AS total_revenue,
  CAST(AVG(price_per_night) AS DECIMAL(19,4))              AS avg_price_per_night,
  COUNT(DISTINCT property_id)                              AS distinct_properties,
  DATE_FORMAT(MIN(check_in),  'yyyy-MM-dd')                AS first_check_in,
  DATE_FORMAT(MAX(check_out), 'yyyy-MM-dd')                AS last_check_out
FROM workspace.`02_silver`.silver_bookings
GROUP BY ALL;