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
// 1) Issue detail query
// 2) Store detail query
// 3) Plot detail query

// Truncate plot to 100 rows
// Link dataset slug to dataset detail page

import { SelfBuildingSquareSpinner } from 'epic-spinners'

export default {
  data() {
    return {
      active: false,
      loaded: false,
      count: 0,
      currentTimestampColumn: null,
      aggregates: null,
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

    endpoint() {
      return `${this.$store.getters.metaEndpoint}/${this.slug}/@aggregate?`
        + `group_by=${this.currentTimestampColumn}&`
        + `granularity=${this.granularity}&`
        + `${this.currentTimestampColumn}=ge:${this.startDate}&`
        + `${this.currentTimestampColumn}=le:${this.endDate}`;
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
      type: Object,
      required: true,
    },
  },

  components: {
    SelfBuildingSquareSpinner
  },

  methods: {
    runQueries: async function() {
      this.loaded = false;
      this.active = false;

      const data = await fetch(this.endpoint)
        .then(response => response.json())
        .catch(error => console.error(error))
        .then(json => json.data);

      this.aggregates = data;
      
      this.count = 0;

      for (var bucket of data) {
        this.count += bucket.count;
      }

      this.loaded = true;
    },

    activate: function() {
      this.active = true;
    },

    deactivate: function() {
      this.active = false;
    }
  },

  mounted() {
    this.currentTimestampColumn = this.timestamps[0];
    this.runQueries(); 
  },
}
</script>
