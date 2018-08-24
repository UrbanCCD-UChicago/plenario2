<template>
  <div class="card">
    <!--
      Spread out evenly accross the top
      -->
    <!-- <SearchParameterBreadcrumbBar
      area-specified
      start-date="foo"
      end-date="bar"
      granularity="day" /> -->

    <!--
      Plot results of aggregate query
      -->
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

    <div v-if="mapIsActive" class="row no-gutters" >
      <div class="col-lg ct-octave" >
        <LMap />
      </div>
    </div>

    <div v-if="!mapIsActive" class="row">
      <div class="col-lg">
        <div id="chart" class="ct-chart ct-octave">
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Chartist from 'chartist';
import 'chartist/dist/chartist.css';
import SearchParameterBreadcrumbBar
  from '../components/SearchParameterBreadcrumbBar.vue';
import LMap from '../components/LMap.vue';

export default {
  components: {
    LMap,
    SearchParameterBreadcrumbBar,
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
    selectedDatasets: function () {
      return this.$store.state.selectedDatasets;
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
