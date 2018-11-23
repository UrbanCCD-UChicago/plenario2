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

    /**
     * The contents of the query string provided by the user. It's represented
     * as an object. For example, a query string like this:
     *
     * ?foo=bar&fizz=buzz
     *
     * will be accessible as an object that looks like this:
     *
     * {
     *   foo: "bar",
     *   fizz: "buzz"
     * }
     *
     * Because this is a computed property, the query value is cached and will
     * not be updated unless the value `$route.query` changes.
     */
    query() {
      return this.$route.query;
    },

    /**
     * Exposes the `startDate` argument of the user provided query string.
     *
     * The `startDate` is used to compose a data query for the back end. The
     * individual data points returned should not have their timestamp values
     * come before the provided `startDate`.
     */
    startDate() {
      return this.query.startDate;
    },

    /**
     * Exposes the `endDate` argument of the user provided query string.
     *
     * The `endDate` is used to compose a data query for the back end. The
     * individual data points returned should not have their timestamp values
     * go later than the provided `endDate`.
     */
    endDate() {
      return this.query.endDate;
    },

    /**
     * Exposes the `granularity` argument of the user provided query string.
     *
     * The `granularity` determines the size of time buckets that results are
     * organized into. This can be any of the following values: hour, day,
     * month, or year.
     */
    granularity() {
      return this.query.granularity;
    },

    /**
     * Exposes the `geojson` argument of the user provided query string.
     *
     * The `geojson` determines the bounding polygon used in the data query.
     * Returned results should not be located anywhere outside of `geojson`.
     *
     * Note that this value is conditional! If it's not provided, the returned
     * results can be located anywhere.
     */
    geojson() {
      if (this.query.geojson) {
        return JSON.stringify(JSON.parse(this.query.geojson).geometry);
      }
    },

    /**
     * Because a dataset can have multiple geospatial fields, we simply
     * grab the first one and use it to compose the data query.
     *
     * todo(heyzoos) Eventually it'd be nice if this could be configurable.
     */
    vpf() {
      return this.meta.virtual_points[0].name;
    },

    /**
     * List of timestamp columns defined for this dataset.
     */
    timestamps() {
      return this.meta.fields.filter((field) => {
        return field.type == "timestamp";
      }).map((field) => {
        return field.name;
      });
    },

    /**
     * This generates a query url for the aggregate endpoint of the backend API. The
     * returned results are this dataset's values organized into buckets. This
     * information is used to plot points on our chart.
     */
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

    /**
     * This generates a query url for the detail endpoint of the backend API. The
     * returned results are this dataset's individual values. This information
     * is used to plot points on our map.
     */
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

    /**
     * This composes the endpoint that takes a user to this dataset's
     * "show" page.
     */
    showEndpoint() {
      return `${this.$store.getters.showEndpoint}/${this.slug}`;
    },

    /**
     * Because all of the dataset metadata is stored in the $store itself,
     * we cache a copy of the value for use in this component.
     */
    meta() {
      return this.$store.state.datasets.find(dset => dset.slug == this.slug);
    },

    /**
     * Provides the download link for this dataset.
     */
    source() {
      return this.meta.source_url;
    },
  },

  props: {

    /**
     * Uniquely identifies this dataset.
     */
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

    /**
     * Invoked as soon as the component is initialized. It fetches both the
     * aggregate data as well as the invidual data points. These values are
     * then used to plot both the map and the charts.
     */
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
     * Adds a new line, representing the aggregates of this dataset.
     * This gets invoked when a user hits the toggle for this dataset row.
     *
     * todo(heyzoos) refactor this or die of shame.
     * todo(heyzoos) died.
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

    /**
     * Removes the plotted line representing this dataset. Invoked when the
     * user toggles this dataset row.
     */
    unplotAggregates() {
      let series = this.chart.data.series;
      let existingData = series.find(o => o.name == this.slug);
      let index = series.indexOf(existingData);
      series.splice(index, 1);
      this.chart.update({series});
    },

    /**
     * Plots all the individual data points for this dataset with a RANDOM color.
     *
     * todo(heyzoos) Use a consistent color pallete!!
     */
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

    /**
     * When the toggle is in an off state and is clicked, this gets invoked.
     *
     * Plots everything.
     */
    activate: function() {
      this.active = true;
      this.plotAggregates();
      this.plotPoints();
    },

    /**
     * When the toggle is in an on state and is clicked, this gets invoked.
     *
     * Unplots everything.
     */
    deactivate: function() {
      this.active = false;
      this.features.clearLayers();
      this.unplotAggregates();
    }
  },

  /**
   * As soon as the dataset row is initialized, go fetch all the data.
   */
  mounted() {
    this.currentTimestampColumn = this.timestamps[0];
    this.runQueries();
  },
}
</script>
