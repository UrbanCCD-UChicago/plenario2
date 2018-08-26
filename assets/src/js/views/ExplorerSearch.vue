<template>
  <div>
    <explorer-search-widget
      @search="search"
      @reset="reset" />
    <explorer-search-results
      v-if="datasets"
      :value="datasets" />
  </div>
</template>

<script>
import ExplorerSearchWidget from '../components/ExplorerSearchWidget.vue';
import ExplorerSearchResults from '../components/ExplorerSearchResults.vue';

export default {
  components: {
    ExplorerSearchWidget,
    ExplorerSearchResults,
  },
  computed: {
    host() { return this.$store.state.host; },
    port() { return this.$store.state.port; },
    ssl() { return this.$store.state.ssl; },
    datasets() { return this.$store.state.datasets; },
    endpoint() { 
      var result = `${this.$store.getters.metaEndpoint}`
        + `?time_range=intersects:{`
        +   `"lower": "${this.$route.query.startDate}",`
        +   `"upper": "${this.$route.query.endDate}",`
        +   `"upper_inclusive": false`
        + `}`;
      
      if (this.$route.query.geojson) {
        // We have to do this because the backend only accepts a polygon...
        var geojson = JSON.parse(this.$route.query.geojson);
        var geometry = geojson.geometry;
        geometry.srid = 4326;
        return result + `&bbox=intersects:${JSON.stringify(geometry)}`;
      } 
      
      else {
        return result;
      }
    },
  },
  methods: {
    async search() {
      // TODO: actually use form data
      const datasets = await fetch(this.endpoint)
        .then(response => response.json())
        .catch(error => console.error(error))
        .then(json => json.data);
      this.$store.commit('setDatasets', datasets);
    },
    reset() { this.$store.commit('clearQuery'); },
  },
};
</script>
