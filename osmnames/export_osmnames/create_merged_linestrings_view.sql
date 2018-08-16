DROP MATERIALIZED VIEW IF EXISTS mv_merged_linestrings;
CREATE MATERIALIZED VIEW mv_merged_linestrings AS
SELECT
  name_en,
  name_de,
  'way'::TEXT as osm_type,
  osm_id::VARCHAR AS osm_id,
  class,
  type,
  round(ST_X(ST_PointOnSurface(ST_Transform(geometry, 4326)))::numeric, 7) AS lon,
  round(ST_Y(ST_PointOnSurface(ST_Transform(geometry, 4326)))::numeric, 7) AS lat,
  place_rank,
  get_importance(place_rank, wikipedia, parentInfo.country_code) AS importance,
  get_country_name(parentInfo.country_code) AS country_en,
  get_country_name_de(parentInfo.country_code) AS country_de,
  parentInfo.country_code AS country_code,
  parentInfo.displayName AS display_name,
  round(ST_XMIN(ST_Transform(geometry, 4326))::numeric, 7) AS west,
  round(ST_YMIN(ST_Transform(geometry, 4326))::numeric, 7) AS south,
  round(ST_XMAX(ST_Transform(geometry, 4326))::numeric, 7) AS east,
  round(ST_YMAX(ST_Transform(geometry, 4326))::numeric, 7) AS north,
FROM
  osm_merged_linestring,
  determine_class(type) AS class,
  get_parent_info(parent_id, name) as parentInfo;
