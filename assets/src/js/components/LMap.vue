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
};

export default {
  props: {
    drawTools: { type: Boolean, default: false },
  },

  data: function () {
    return {
      drawnItems: null,
      geojson: this.$route.query.geojson,
    }
  },
  mounted() {
    const map = L.map(this.$el).setView([41.8781, -87.6298], 13);

    L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png').addTo(map);

    if (this.drawTools) {
      this.drawnItems = new L.FeatureGroup().addTo(map);
      new L.Control.Draw({
        draw: enabledDrawTools,
        edit: { featureGroup: this.drawnItems },
      }).addTo(map);
      map.on('draw:created', this.onDraw);

      this.drawnItems.clearLayers();

      if (this.geojson) {
        L.geoJSON(JSON.parse(this.geojson)).addTo(this.drawnItems);
      }
    }
  },

  updated: function() {
    console.log(this.geojson);
    this.drawnItems.clearLayers();
    L.geoJSON(this.geojson).addTo(this.drawnItems);
  },

  methods: {
    onDraw(event) {
      this.drawnItems.clearLayers();
      this.drawnItems.addLayer(event.layer);

      var query = Object.assign({}, this.$route.query, {
        geojson: JSON.stringify(event.layer.toGeoJSON())
      });


      var clone = JSON.parse(JSON.stringify(query));

      this.$router.replace({
        name: 'search', 
        query: clone,
      });
    }
  },
};
</script>

