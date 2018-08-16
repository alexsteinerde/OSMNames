DROP FUNCTION IF EXISTS get_names(TEXT, HSTORE);
CREATE FUNCTION get_names(current_name TEXT, all_tags HSTORE)
RETURNS TABLE(name TEXT, name_en TEXT, name_de TEXT, alternative_names_string TEXT) AS $$
DECLARE
  accepted_name_tags TEXT[] := ARRAY['name','name:left','name:right','int_name','loc_name','nat_name',
                                     'official_name','old_name','reg_name','short_name','alt_name'];
  alternative_names TEXT[];
BEGIN
  SELECT array_agg(DISTINCT(all_tags -> key))
    FROM unnest(akeys(all_tags)) AS key
    WHERE key LIKE 'name:__' OR key = ANY(accepted_name_tags)
    INTO alternative_names;

  name := current_name;
  IF name = '' IS NOT FALSE THEN
    SELECT COALESCE(
                  all_tags -> 'name',
                  all_tags -> 'name:fr',
                  all_tags -> 'name:de',
                  all_tags -> 'name:es',
                  all_tags -> 'name:ru',
                  all_tags -> 'name:zh',
                  alternative_names[1])
      INTO name;
  END IF;
  name := regexp_replace(name, E'\\s+', ' ', 'g');

  SELECT COALESCE(
                all_tags -> 'name:de',
                all_tags -> 'name:en',
                all_tags -> 'name')
    INTO name_de;
  name_de := regexp_replace(name_de, E'\\s+', ' ', 'g');

  SELECT COALESCE(
                all_tags -> 'name:en',
                all_tags -> 'name')
    INTO name_en;
  name_en := regexp_replace(name_en, E'\\s+', ' ', 'g');

  alternative_names := array_remove(alternative_names, name);
  alternative_names_string := array_to_string(alternative_names, ',');
  alternative_names_string := regexp_replace(alternative_names_string, E'\\s+', ' ', 'g');

  IF alternative_names_string = '' THEN
    alternative_names_string = NULL;
  END IF;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


UPDATE osm_linestring SET (name, name_en, name_de, alternative_names) = (SELECT * FROM get_names(name, all_tags));
UPDATE osm_polygon SET (name, name_en, name_de, alternative_names) = (SELECT * FROM get_names(name, all_tags));
UPDATE osm_point SET (name, name_en, name_de, alternative_names) = (SELECT * FROM get_names(name, all_tags));
