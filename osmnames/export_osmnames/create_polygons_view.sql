DROP MATERIALIZED VIEW IF EXISTS mv_polygons;
CREATE MATERIALIZED VIEW mv_polygons AS
SELECT
  name_en,
  name_de,
  CASE WHEN osm_id > 0 THEN 'way' ELSE 'relation' END AS osm_type,
  abs(osm_id)::VARCHAR as osm_id,
  determine_class(type) AS class,
  type,
  round(ST_X(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0)))::numeric::numeric, 7) AS lon,
  round(ST_Y(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0)))::numeric::numeric, 7) AS lat,
  place_rank,
  get_importance(place_rank, wikipedia, parentInfo.country_code) AS importance,
  get_country_name(parentInfo.country_code) AS country_en,
  get_country_name_de(parentInfo.country_code) AS country_de,
  parentInfo.country_code AS country_code,
  bounding_box[1] AS west,
  bounding_box[2] AS south,
  bounding_box[3] AS east,
  bounding_box[4] AS north
FROM
  osm_polygon,
  get_parent_info(id, '') as parentInfo,
  get_bounding_box(geometry, parentInfo.country_code, admin_level) AS bounding_box;
