-- ============================================================
-- SILVER: clean all data-quality issues
-- ============================================================
CREATE OR REFRESH MATERIALIZED VIEW workspace.`02_silver`.silver_bookings
(
  booking_id          STRING,
  user_id             STRING,
  property_id         STRING,
  city                STRING,
  room_type           STRING,
  check_in            DATE,
  check_out           DATE,
  check_in_display    STRING,
  check_out_display   STRING,
  nights_stayed       INT,
  guests_count        INT,
  total_amount        DECIMAL(19,4),
  price_per_night     DECIMAL(19,4),
  status              STRING,
  payment_method      STRING,
  booking_channel     STRING,
  created_at          TIMESTAMP,
  updated_at          TIMESTAMP,
  ingested_at         TIMESTAMP
)
AS
WITH cleaned AS (
  SELECT
    TRIM(booking_id)                                    AS booking_id,
    TRIM(user_id)                                       AS user_id,
    TRIM(property_id)                                   AS property_id,

    -- city: fix casing, typos, blanks
    CASE
      WHEN LOWER(TRIM(city)) = 'bali'                        THEN 'Bali'
      WHEN LOWER(TRIM(city)) IN ('cape town', 'capetown')    THEN 'Cape Town'
      WHEN LOWER(TRIM(city)) = 'barcelona'                   THEN 'Barcelona'
      WHEN LOWER(TRIM(city)) = 'lisbon'                      THEN 'Lisbon'
      WHEN LOWER(TRIM(city)) = 'reykjavik'                   THEN 'Reykjavik'
      WHEN LOWER(TRIM(city)) IN ('tokyo', 'tokio')           THEN 'Tokyo'
      WHEN TRIM(city) = '' OR city IS NULL                   THEN 'unknown'
      ELSE INITCAP(TRIM(city))
    END                                                 AS city,

    -- room_type: strip stray spaces
    TRIM(room_type)                                     AS room_type,

    -- check_in / check_out: dd-MM-yy dates
    TO_DATE(check_in,  'dd-MM-yy')                      AS check_in,
    TO_DATE(check_out, 'dd-MM-yy')                      AS check_out,
    DATE_FORMAT(TO_DATE(check_in,  'dd-MM-yy'), 'yyyy-MM-dd') AS check_in_display,
    DATE_FORMAT(TO_DATE(check_out, 'dd-MM-yy'), 'yyyy-MM-dd') AS check_out_display,

    CAST(nights_stayed AS INT)                          AS nights_stayed,
    CAST(guests_count  AS INT)                          AS guests_count,

    -- numerics: blanks -> 0
    CAST(COALESCE(total_amount,    0) AS DECIMAL(19,4)) AS total_amount,
    CAST(COALESCE(price_per_night, 0) AS DECIMAL(19,4)) AS price_per_night,

    -- status: unify casing + canceled/cancelled spelling
    CASE
      WHEN LOWER(TRIM(status)) IN ('cancelled', 'canceled') THEN 'cancelled'
      WHEN LOWER(TRIM(status)) = 'confirmed'                 THEN 'confirmed'
      WHEN LOWER(TRIM(status)) = 'completed'                 THEN 'completed'
      WHEN LOWER(TRIM(status)) = 'pending'                   THEN 'pending'
      ELSE LOWER(TRIM(status))
    END                                                 AS status,

    -- payment_method: trim, blanks/'nan' -> NULL
    CASE
      WHEN TRIM(LOWER(payment_method)) IN ('', 'nan') OR payment_method IS NULL
        THEN NULL
      ELSE TRIM(LOWER(payment_method))
    END                                                 AS payment_method,

    -- booking_channel: blanks -> unknown
    CASE
      WHEN TRIM(booking_channel) = '' OR booking_channel IS NULL THEN 'unknown'
      ELSE LOWER(TRIM(booking_channel))
    END                                                 AS booking_channel,

    -- ISO timestamps cast natively
    CAST(created_at AS TIMESTAMP)                       AS created_at,
    CAST(updated_at AS TIMESTAMP)                       AS updated_at,

    ingested_at,

    -- dedup: keep one row per booking_id (latest updated_at wins)
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(booking_id)
      ORDER BY CAST(updated_at AS TIMESTAMP) DESC
    )                                                   AS rn
  FROM workspace.`01_bronze`.bronze_bookings
  -- drop rows with unparseable / illogical stay dates
  WHERE TO_DATE(check_out, 'dd-MM-yy') >= TO_DATE(check_in, 'dd-MM-yy')
)
SELECT
  booking_id, user_id, property_id, city, room_type,
  check_in, check_out, check_in_display, check_out_display,
  nights_stayed, guests_count, total_amount, price_per_night,
  status, payment_method, booking_channel,
  created_at, updated_at, ingested_at
FROM cleaned
WHERE rn = 1;