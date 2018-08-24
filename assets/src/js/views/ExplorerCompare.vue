<template>
  <section class="container">
    <SearchParameterBreadcrumbBar
      area-specified
      start-date="foo"
      end-date="bar"
      granularity="day" />
    <div id="plotting-area"
         class="row no-gutters" >
      <div id="map-plot-area"
           class="col-lg-5" >
        <LMap />
      </div>
      <div id="chart-plot-area"
           class="col-lg-7">
        <div id="chart"
             class="ct-chart ct-golden-section">
        </div>
      </div>
    </div>
  </section>
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
  }),
  mounted() {
    this.chart = new Chartist.Line('#chart', this.chartData);
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

  mounted: function() {
    new Chartist.Line('#chart', this.chartData);
  }
};
</script>
