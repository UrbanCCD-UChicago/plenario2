<template>
  <div class="map h-100">
  </div>
</template>

<script>
import L from 'leaflet';
import 'leaflet-draw';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';

const enabledDrawTools = {
  // Ommitted tools are enabled by default
  marker:       false,
  circlemarker: false,
  polyline:     false,
  circle:       false,
};

const subdomain = 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png';

const drawOptions = { draw: enabledDrawTools };

export default {
  props: {
    drawTools: { type: Boolean, default: false },
  },

  data: function () {
    return {
      geojson: this.$route.query.geojson,
      lmap: null,
      drawableFeatureGroup: null,
      tileLayer: null,
    }
  },

  mounted() {
    this.initMap();
    this.possiblyInitDrawTools();
    this.draw(L.geoJSON(JSON.parse(this.geojson)));
  },

  methods: {

    /**
     * Set our map and tile layer, add the layer to the map.
     */
    initMap() {
      this.lmap = L.map(this.$el).setView([41.8781, -87.6298], 13);
      this.tileLayer = L.tileLayer(subdomain).addTo(this.lmap);
    },

    /**
     * Conditionally display the drawing tools, depends on this.drawTools.
     */
    possiblyInitDrawTools() {
      if (this.drawTools) {
        this.drawableFeatureGroup = new L.FeatureGroup().addTo(this.lmap);
        new L.Control.Draw(drawOptions).addTo(this.lmap);
        this.lmap.on('draw:created', this.onDraw);
      }
    },

    /**
     * Updates the `geojson` query argument in the url.
     */
    updateUrl(geojson) {
      var query = Object.assign({}, this.$route.query, { geojson });
      var clone = JSON.parse(JSON.stringify(query));
      this.$router.replace({ name: 'search', query: clone });
    },

    /**
     * Draw a layer to the map. It clears away the previous layers.
     */
    draw(layer) {
      this.drawableFeatureGroup.clearLayers();
      this.drawableFeatureGroup.addLayer(layer);
    },

    /**
     * Callback that fires when the user has drawn a polygon on the map.
     */
    onDraw(event) {
      this.draw(event.layer);
      this.updateUrl(JSON.stringify(event.layer.toGeoJSON()));
    },
  },
};
</script>
