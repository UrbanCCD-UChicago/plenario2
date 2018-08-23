<template>
  <div class="row">
    <div class="col-12">
      <span class="text-muted">
        <search-parameter-breadcrumb v-if="areaSpecified" icon="fa-map" text="area-specified" />
        <search-parameter-breadcrumb icon="fa-calendar" :text="startToEndDate" />
        <search-parameter-breadcrumb icon="fa-clock" :text="'aggregate by ' + granularity" />
      </span>
    </div>
  </div> 
</template>

<script>
import SearchParameterBreadcrumb from './SearchParameterBreadcrumb.vue';

export default {
  props: {
    areaSpecified: {
      type: Boolean,
      required: true
    },

    startDate: {
      type: String,
      required: true
    },

    endDate: {
      type: String,
      required: true
    },

    granularity: {
      type: String,
      required: true
    }
  },

  computed: {
    startToEndDate: function () {
      return this.startDate + ' - ' + this.endDate;
    }
  },

  components: { 
    SearchParameterBreadcrumb 
  }  
}
</script>
