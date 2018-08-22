<template>
  <div class="map"></div>
</template>


<style lang="scss" scoped>
.map {
  width: 100%;
  height: 100%;
}
</style>


<script>
import L from 'leaflet';
import 'leaflet-draw';
import "leaflet/dist/leaflet.css";

export default {

  data: function () {
    return {
      drawnItems: new L.FeatureGroup()
    }
  },

  /**
   * Called after the instance has been mounted, where el is replaced by the 
   * newly created vm.$el. If the root instance is mounted to an in-document 
   * element, vm.$el will also be in-document when mounted is called.
   */
  mounted: function () {
    // 
    const map = L.map(this.$el).setView([41.8781, -87.6298], 13);

    // 
    L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png').addTo(map);

    // FeatureGroup is to store editable layers
    var drawControl = new L.Control.Draw({
      edit: {
        featureGroup: this.drawnItems
      }
    });

    //
    map.addLayer(this.drawnItems);
    map.addControl(drawControl);

    //
    map.on('draw:created', this.onDraw);
  },

  methods: {
    onDraw: function (event) {
      this.drawnItems.clearLayers();
      this.drawnItems.addLayer(event.layer);
    }
  }
}
</script>

