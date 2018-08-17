<template>
  <section class="container">
    <search-parameter-breadcrumbs area-specified
      start-date="foo"
      end-date="bar"
      granularity="day" />
    
    <div class="row no-gutters" id="plotting-area">
      <div class="col-lg-5 card" id="map-plot-area">
        <!-- <l-map></l-map> -->
      </div> <!-- map-plot-area -->

      <div class="col-lg-7" id="chart-plot-area">
        <div class="ct-chart ct-golden-section" id="chart">
        </div>
      </div> <!-- chart-plot-area -->

      <div class="col-12">
        <h1>
          View &amp; Compare
        </h1>
      </div>
    </div> <!-- plotting-area -->
  </section>
</template>

<script>
import Chartist from 'chartist';

import LMap from './LMap.vue';
import SearchParameterBreadcrumbs from './SearchParameterBreadcrumbs.vue';

export default {
  components: {
    LMap,
    SearchParameterBreadcrumbs
  },

  data: function () {
    return {
      chartData: {
          labels: ["A", "B", "C"],
          series:[[1, 3, 2], [4, 6, 5]]
      },
      chartOptions: {
          lineSmooth: false
      }
    }
  },

  mounted: function() {
    new Chartist.Line('#chart', this.chartData);
  }
}
</script>
