<template>
  <div class="col-12">

    <div class="form-group row">
      <label class="col-3" for="starting_on">Start</label>
      <datepicker class="col-9" v-model="startDate"></datepicker>
    </div>

    <div class="form-group row">
      <label class="col-3" for="ending_on">End</label>
      <datepicker class="col-9" v-model="endDate"></datepicker>
    </div>

    <div class="form-group row">
      <label for="granularity" class="control-label col-4">Granularity</label>
      <select id="granularity" name="granularity" class="form-control col-7" v-model="granularity" required>
        <option value="day">Day</option>
        <option value="week">Week</option>
        <option value="month">Month</option>
        <option value="year">Year</option>
      </select>
    </div>

    <div class="action-card float-xl-left pr-xl-1">
      <div class="card action-card">
        <div class="card-body">
          <div class="row align-items-center">
            <div class="col-12 col-md-6 col-xl-12 px-3">
              <div class="card-text mb-3 mb-md-0 mb-xl-3">
                When you're ready, click search.
              </div>
            </div>
            <div class="col-6 col-md-3 col-xl-6 pr-1">
              <button @click="reset" type="button" class="btn btn-danger">
                <i class="fas fa-undo"></i>
                Reset
              </button>
            </div>
            <div class="col-6 col-md-3 col-xl-6 pl-1">
              <button @click="search" type="button" class="btn btn-primary">
                <i class="fas fa-search"></i>
                Search
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

/**
 * A component for choosing a date. We use this to provide time range query
 * parameters to the backend api.
 */
import Datepicker from 'vuejs-datepicker';

export default {
  name: 'TimeRangeForm',
  data: function () {
    return {
      startDate: '',
      endDate: '',
      granularity: ''
    }
  },

  components: {
    Datepicker
  },

  /**
   * Functions that hang off the vue component instance. These are used to
   * navigate and manipulate state.
   */
  methods: {

    /**
     * The handler for click events on our search button. This function should
     * take the data we currently have, formulate a query, and send us to the
     * next stage of the search page.
     */
    search: function (_) {
      console.log('Hello!');
    },

    /**
     * The handler for click events on our reset button. This function should
     * clear the data contained in the component.
     */
    reset: function (_) {
      this.startDate = null;
      this.endDate = null;
      this.granularity = null;
    }
  }
};
</script>
 