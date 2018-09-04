<template>
  <tr>
    <th scope="row">
      <self-building-square-spinner 
        v-if="!loaded"
        :animation-duration="6000"
        :size="20"
        color="#ff1d5e"
      />
      <FontAwesomeIcon @click="activate" v-else-if="!active" icon="toggle-off" />
      <FontAwesomeIcon @click="deactivate" v-else icon="toggle-on" />
    </th>
    <td>{{ slug }}</td>
    <td>
      <button class="btn btn-sm btn-outline-info dropdown-toggle" 
        type="button" id="dropdownMenu2" 
        data-toggle="dropdown" 
        aria-haspopup="true" 
        aria-expanded="false">
        {{ currentTimestampColumn }}
      </button>
      <div class="dropdown-menu">
        <a v-for="timestamp in timestamps" 
          :key="timestamp" 
          class="dropdown-item">
          {{ timestamp }}
        </a>
      </div>
    </td>
    <td>
      <self-building-square-spinner 
        v-if="!loaded"
        :animation-duration="6000"
        :size="20"
        color="#ff1d5e"
      />
      <div v-else>{{ count }} rows</div>
    </td>
  </tr>
</template>

<script>
import { SelfBuildingSquareSpinner } from 'epic-spinners'
import Chartist from 'chartist';

export default {
  data() {
    return {
      active: false,
      loaded: false,
      count: 0,
      currentTimestampColumn: null,
      aggregates: null,
      points: null,
      features: new L.FeatureGroup()
    };
  },

  computed: {
    query() {
      return this.$route.query;
    },

    startDate() {
      return this.query.startDate;
    },

    endDate() {
      return this.query.endDate;
    },

    granularity() {
      return this.query.granularity;
    },

    geojson() {
      return this.query.geojson;
    },

    /**
     * List of timestamp column names. We get this information from the dataset
     * objects in the store. 
     */
    timestamps() {
      let dataset = this.$store.state.datasets.find((dataset) => {
        return dataset.slug == this.slug;
      });

      return dataset.fields.filter((field) => {
        return field.type == "timestamp";
      }).map((field) => {
        return field.name;
      });
    },

    // Make use of geom filter
    aggregateEndpoint() {
      return `${this.$store.getters.metaEndpoint}/${this.slug}/@aggregate?`
        + `group_by=${this.currentTimestampColumn}&`
        + `granularity=${this.granularity}&`
        + `${this.currentTimestampColumn}=ge:${this.startDate}&`
        + `${this.currentTimestampColumn}=le:${this.endDate}`;
    },

    // Make use of geom filter
    detailEndpoint() {
      return `${this.$store.getters.metaEndpoint}/${this.slug}/?`
        + `format=geojson&`
        + `${this.currentTimestampColumn}=ge:${this.startDate}&`
        + `${this.currentTimestampColumn}=le:${this.endDate}&`;
    },

    lmap: function () {
      return this.$store.state.compareMap;
    }
  },

  props: {
    slug: {
      type: String,
      required: true,
    },

    /**
     * A reference to the chart to plot over when activated.
     */
    chart: {
      type: Object,
      required: true,
    },

    /**
     * A reference to the leaflet map to plot over.
     */
    lmap: {
      type: Object,
    }
  },

  components: {SelfBuildingSquareSpinner},

  methods: {
    runQueries: async function() {
      this.loaded = false;
      this.active = false;

      this.aggregates = await fetch(this.aggregateEndpoint)
        .then(response => response.json())
        .catch(error => console.error(error))
        .then(json => json.data);

      this.points = await fetch(this.detailEndpoint)
        .then(response => response.json())
        .catch(error => console.error(error))
        .then(json => json.data);
      
      this.count = this.aggregates.reduce((acc, bucket) => {
        return acc + bucket.count;
      }, 0);

      this.loaded = true;
    },

    plotAggregates: function() {
      let data = this.aggregates.map((row) => {
        return {x: Date.parse(row.bucket), y: row.count};
      });

      this.chart = new Chartist.Line('#chart', {series: [
        {name: 'foo', data: data}
      ]}, {
        axisX: {
          type: Chartist.FixedScaleAxis,
          divisor: 10,
          labelInterpolationFnc: (value) => {
            return new Date(value).toISOString();
          },
        }
      });
    },

    plotPoints: function() {
      let r = Math.floor(Math.random() * 255);
      let g = Math.floor(Math.random() * 255);
      let b = Math.floor(Math.random() * 255);
      let color = "rgb("+r+" ,"+g+","+ b+")"; 

      this.points.map((point) => {
        let latitude = point.geometry.coordinates[0];
        let longitude = point.geometry.coordinates[1];
        L.circle([longitude, latitude], {color: color, radius: 15}).addTo(this.features);
      });
      this.features.addTo(this.lmap);
    },

    activate: function() {
      this.active = true;
      this.plotAggregates();
      this.plotPoints();
    },

    deactivate: function() {
      this.active = false;
      this.features.clearLayers();
    }
  },

  mounted() {
    this.currentTimestampColumn = this.timestamps[0];
    this.runQueries(); 
  },
}
</script>
