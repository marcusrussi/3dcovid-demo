joined2.geojson: us-counties-latest-infections.json counties-10m.json
	ndjson-join --right 'd.id' \
	  counties-10m.json \
	  us-counties-latest-infections.json | \
	ndjson-map \
	  'd[0].properties = {infections: d[1].infections || 0}, d[0]' | \
	ndjson-reduce | \
	ndjson-map '{type: "FeatureCollection", features: d}' > $@

joined.geojson: us-counties-latest-infections.json counties-10m.json
	ndjson-join --right 'd.id' \
	  counties-10m.json \
	  us-counties-latest-infections.json | \
	ndjson-map \
	  'd[0].properties = {infections: d[1].infections || 0}, d[0]' | \
	ndjson-reduce | \
	ndjson-map '{type: "FeatureCollection", features: d}' > $@

us-counties-latest-infections.json: summary.csv
	./prepForGeoJoin.R -o tmp.json --summary summary.csv -1
	ndjson-split 'd.slice(1)' < tmp.json > $@
	@rm tmp.json

us-counties-latest-infections-withpop.ndjson: summary.csv
	./prepForGeoJoin.R -o tmp2.json --summary summary.csv -1 --pop
	ndjson-split 'd.slice(1)' < tmp2.json > $@
	@rm tmp2.json

counties-10m.json: counties-10m.topojson
	topo2geo counties=tmp1.json < $<
	ndjson-split 'd.features' < tmp1.json > $@
	@rm tmp1.json

towns-joined.json: towns.ndjson us-counties-latest-infections-withpop.ndjson
	ndjson-join 'd.id' \
	  towns.ndjson \
	  us-counties-latest-infections-withpop.ndjson | \
	ndjson-map \
	  'd[0].properties = {infections: d[1].infections || 0, multiplier: d[0].properties.pop_2010/d[1].pop}, d[0]' | \
	ndjson-reduce > $@

towns.ndjson: towns.json
	ndjson-split 'd.features' < $< | \
	  ndjson-map 'd.id = d.properties.state_fips + d.properties.countyfips, d' > $@
