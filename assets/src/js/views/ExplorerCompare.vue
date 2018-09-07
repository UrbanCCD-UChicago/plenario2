<template>
  <div class="card">
    <!-- rely on built in bootstrap active/inactive state -->
    <ul class="nav nav-fill">
      <button class="nav-item btn btn-outline-primary border-0 m-1" @click="selectMap">
        <FontAwesomeIcon icon="map" />
        Map
      </button>
      <button class="nav-item btn btn-outline-primary border-0 m-1" @click="selectChart">
        <FontAwesomeIcon icon="chart-line" />
        Charts
      </button>
    </ul>

    <!-- rely on built in bootstrap active/inactive state -->
    <div v-show="mapIsActive" class="row no-gutters" >
      <div class="col-lg ct-octave" >
        <LMap v-on:lmapMounted="onLmapMounted" />
      </div>
    </div>

    <div v-show="!mapIsActive" class="row">
      <div class="col-lg">
        <div id="chart" class="ct-chart ct-octave">
        </div>
      </div>
    </div>

    <table class="table table-hover p-bottom-0">
      <thead>
        <tr>
          <th scope="col">Display</th>
          <th scope="col">Dataset Name</th>
          <th scope="col">Aggregate By</th>
          <th scope="col">Query Result Count</th>
          <th scope="col">Download Source</th>
        </tr>
      </thead>
      <tbody>
        <DataSetRow 
          v-for="datasetSlug in selectedDatasetSlugs" 
          :key="datasetSlug"
          :lmap="lmap"
          :slug="datasetSlug" 
          :chart="chart" />
      </tbody>
    </table>
  </div>
</template>


<script>
import Chartist from 'chartist';
import 'chartist/dist/chartist.min.css';
import LMap from '../components/LMap.vue';
import DataSetRow from '../components/DataSetRow.vue';

export default {
  components: {LMap, DataSetRow},

  data: function () {
    return {
      mapIsActive: true,
      chart: null,
      lmap: null,
    }
  },

  computed: {

    /**
     * These are the datasets to render on the map and in our chart. This list
     * is filtered by selections made in the search widget.
     */
    selectedDatasetSlugs: function () {
      var datasets = this.$route.query['data-sets'];

      // When a single dataset argument is provided, we receive it as a string.
      // Iterating over the string will generate a table element for every
      // character.
      if (typeof(datasets) == 'object') {
        return datasets;
      } else {
        return [datasets];
      }
    },
  },

  mounted: function() {
    this.chart = new Chartist.Line('#chart');
  },

  methods: {
    selectMap: function () {
      this.mapIsActive = true;

      // todo(heyzoos) Find a better solution to this bug and its sibling.
      //
      // This is a janky solution to a bug. The map just stops updating when
      // you plot data while the map is hidden. 
      //
      // Provide 1000 as the second argument to `setTimeout` to see the bug in
      // action.
      setTimeout(() => { window.dispatchEvent(new Event('resize')) });
    },

    selectChart: function () {
      this.mapIsActive = false;

      // This is a janky solution to a bug. The charts are confined to a 1x1 
      // pixel space when you plot data while the chart is hidden. After you
      // unhide the chart, the data stays in that 1x1 pixel space until a
      // resize event.
      //
      // Provide 1000 as the second argument to `setTimeout` to see the bug in
      // action.
      setTimeout(() => { window.dispatchEvent(new Event('resize')) });
    }, 

    onLmapMounted: function (lmap) {
      this.lmap = lmap;
    },
  },
};
</script>
