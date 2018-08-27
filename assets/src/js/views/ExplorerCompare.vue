<template>
  <div class="card">
    <!-- rely on built in bootstrap active/inactive state -->
    <ul class="nav nav-fill">
      <li class="nav-item">
        <a :class="mapIsActive ? activeClasses : inactiveClasses" @click="selectMap">
          <FontAwesomeIcon icon="map" />
          Map
        </a>
      </li>
      <li class="nav-item">
        <a :class="mapIsActive ? inactiveClasses : activeClasses" @click="selectChart">
          <FontAwesomeIcon icon="chart-line" />
          Charts
        </a>
      </li>
    </ul>

    <!-- rely on built in bootstrap active/inactive state -->
    <div v-show="mapIsActive" class="row no-gutters" >
      <div class="col-lg ct-octave" >
        <LMap />
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
          <th scope="col">Result Count</th>
        </tr>
      </thead>
      <tbody>
        <DataSetRow 
          v-for="datasetSlug in selectedDatasetSlugs" 
          :key="datasetSlug"
          :slug="datasetSlug" 
          :chart="chart" />
      </tbody>
    </table>
  </div>
</template>

<script>
import Chartist from 'chartist';
import 'chartist/dist/chartist.css';
import SearchParameterBreadcrumbBar
  from '../components/SearchParameterBreadcrumbBar.vue';
import LMap from '../components/LMap.vue';
import DataSetRow from '../components/DataSetRow.vue';

export default {
  components: {
    LMap,
    SearchParameterBreadcrumbBar,
    DataSetRow,
  },
  data: () => ({
    chartData: {
      labels: ['A', 'B', 'C'],
      series: [[1, 3, 2], [4, 6, 5]],
    },
    chartOptions: {
      lineSmooth: false,
    },
    chart: undefined,

    mapIsActive: true,

    activeClasses: {
      'nav-link': true,
      'py-2': true,
      'active': true,
      'bg-primary': true,
      'text-white': true,
      'font-weight-bold': true,
    },

    inactiveClasses: {
      'nav-link': true,
      'py-2': true,
      'text-primary': true
    },
  }),

  updated() {
    if (!this.mapIsActive) {
      this.chart = new Chartist.Line('#chart', this.chartData);
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

  methods: {
    selectMap: function () {
      this.mapIsActive = true;
    },

    selectChart: function () {
      this.mapIsActive = false;
    }, 
  }
};
</script>
