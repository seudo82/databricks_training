-- ============================================================
-- BRONZE: read selected column from raw.
-- ============================================================
CREATE OR REFRESH MATERIALIZED VIEW workspace.`01_bronze`.bronze_bookings
AS
SELECT
  no,
  booking_id,
  user_id,
  property_id,
  city,
  room_type,
  check_in,
  check_out,
  nights_stayed,
  guests_count,
  total_amount,
  price_per_night,
  status,
  payment_method,
  booking_channel,
  created_at,
  updated_at,
  current_timestamp() AS ingested_at
FROM workspace.`00_raw`.raw_bookings;