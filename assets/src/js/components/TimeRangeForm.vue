<template>
  <div class="time-range-form">
    <div class="form-group form-row">
      <label class="col-sm-1 col-lg-2 col-form-label" for="starting_on">Start</label>
      <datepicker required bootstrap-styling
        class="col" 
        input-class="bg-white"
        v-model="startDate" />
    </div>
    <div class="form-group form-row">
      <label class="col-sm-1 col-lg-2 col-form-label" for="ending_on">End</label>
      <datepicker required bootstrap-styling
        class="col" 
        input-class="bg-white" 
        v-model="endDate" />
    </div>
    <div class="form-group form-row">
      <label for="granularity" class="col-sm-2 col-sm-4 col-form-label">Granularity</label>
      <div class="col">
        <select required 
          id="granularity" 
          name="granularity" 
          class="custom-select"
          v-model="granularity">
          <option value="day">Day</option>
          <option value="week">Week</option>
          <option value="month">Month</option>
          <option value="year">Year</option>
        </select>
      </div>
    </div>
  </div>
</template>

<style lang="scss">
@import "~bootstrap/scss/functions";
@import "~bootstrap/scss/variables";

.vdp-datepicker__calendar { z-index: $zindex-popover; }
</style>


<script>
/**
 * A component for choosing a date. We use this to provide time range query
 * parameters to the backend api.
 */
import Datepicker from 'vuejs-datepicker';

export default {
  name: 'TimeRangeForm',

  data: function () {
    var endDateDefault = new Date();
    var startDateDefault = new Date()
      .setDate(endDateDefault.getDate() - 90);
    startDateDefault = new Date(startDateDefault);

    return {
      startDate: this.$route.query.startDate ?
        new Date(this.$route.query.startDate) :
        startDateDefault,
      endDate: this.$route.query.endDate ?
        new Date(this.$route.query.endDate) :
        endDateDefault,
      granularity: this.$route.query.granularity ?
        this.$route.query.granularity : 
        'month',
    };
  },

  /**
   * The cloning here occurs because of the way the vue router
   * seems to track changes. It would not update the url parameters
   * unless the object itself was different. Shallow copies with
   * shared references were not enough.
   */
  updated() {
    this.updateUrl();
  },

  mounted() {
    this.updateUrl();
  },

  methods: {

    /**
     * Updates the url query values with the current data in our
     * time range form.
     * 
     * TODO: Note how we have to slice off the milliseconds from our strings?
     *    The backend cannot parse timestamps if we include them for some reason.
     */
    updateUrl() {
      var query = Object.assign({}, this.$route.query, {
        startDate: this.startDate.toISOString().slice(0, -5),
        endDate: this.endDate.toISOString().slice(0, -5),
        granularity: this.granularity
      });

      var clone = JSON.parse(JSON.stringify(query));

      this.$router.replace({
        name: 'search', 
        query: clone,
      });
    }
  },

  components: {
    Datepicker
  },
};
</script>
 