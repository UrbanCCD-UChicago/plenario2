<template>
  <tr>
    <th scope="row">
      <self-building-square-spinner 
        v-if="!loaded"
        :animation-duration="6000"
        :size="20"
        color="#ff1d5e"
      />
      <button class="btn btn-outline-primary border-0" @click="activate" v-else-if="!active">
        <FontAwesomeIcon icon="toggle-off" />
      </button>
      <button class="btn btn-outline-primary border-0" @click="deactivate" v-else>
        <FontAwesomeIcon icon="toggle-on" />
      </button>
    </th>
    <td>
      <a :href="showEndpoint" class="btn btn-outline-primary border-0">
        {{ meta.name }}
      </a>
    </td>
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
    <td>
      <a :href="source" class="btn btn-outline-primary border-0">
        <FontAwesomeIcon icon="download" />
      </a>
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
      if (this.query.geojson) {
        return JSON.stringify(JSON.parse(this.query.geojson).geometry);
      }
    },

    vpf() {
      return this.meta.virtual_points[0].name;
    },

    /**
     * List of timestamp column names. We get this information from the dataset
     * objects in the store. 
     */
    timestamps() {
      return this.meta.fields.filter((field) => {
        return field.type == "timestamp";
      }).map((field) => {
        return field.name;
      });
    },

    aggregateEndpoint() {
      let query = `${this.$store.getters.metaEndpoint}/${this.slug}/@aggregate?`
        + `${this.currentTimestampColumn}=within:{`
        +   `"lower": "${this.startDate}",`
        +   `"upper": "${this.endDate}",`
        +   `"upper_inclusive": true`
        + `}&`
        + `group_by=${this.currentTimestampColumn}&`
        + `granularity=${this.granularity}`;

      if (this.geojson) {
        return query + `&${this.vpf}=within:${this.geojson}`;
      } else {
        return query;
      }
    },

    detailEndpoint() {
      let query = `${this.$store.getters.metaEndpoint}/${this.slug}/?`
        + `${this.currentTimestampColumn}=within:{`
        +   `"lower": "${this.startDate}",`
        +   `"upper": "${this.endDate}",`
        +   `"upper_inclusive": true`
        + `}&`
        + `format=geojson&`;

      if (this.geojson) {
        return query + `${this.vpf}=within:${this.geojson}`;
      } else {
        return query;
      }
    },

    showEndpoint() {
      return `${this.$store.getters.showEndpoint}/${this.slug}`;
    }, 

    meta() {
      return this.$store.state.datasets.find(dset => dset.slug == this.slug);
    },
    
    source() {
      return this.meta.source_url;
    },
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
      required: true,
    },

    /**
     * A reference to the leaflet map to plot over.
     */
    lmap: {
      required: true,
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

    /**
     * todo(heyzoos) refactor this or die of shame
     */
    plotAggregates: function() {
      let data = {
        name: this.slug, 
        data: this.aggregates.map((row) => {
          return {x: Date.parse(row.bucket), y: row.count};
        }),
      };

      let series = this.chart.data.series;
      series.push(data);

      this.chart = new Chartist.Line('#chart', {series}, {
        axisX: {
          type: Chartist.FixedScaleAxis,
          divisor: 5,
          labelInterpolationFnc: (value) => {
            return new Date(value).toISOString();
          },
        }
      });
    },

    unplotAggregates() {
      let series = this.chart.data.series;
      let existingData = series.find(o => o.name == this.slug);
      let index = series.indexOf(existingData);
      series.splice(index, 1);
      this.chart.update({series});
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
      this.unplotAggregates();
    }
  },

  mounted() {
    this.currentTimestampColumn = this.timestamps[0];
    this.runQueries(); 
  },
}
</script>
