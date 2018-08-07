<template>
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
</template>


<script>
export default {
  name: 'ActionCard',
  
  props: {

    /**
     * Host url of the target backend. This can change depending on the 
     * application context. For example, in a development application this
     * value could be localhost:4000, in production, it could be the url of
     * the live server.
     */
    url: {
      required: true,
      type: String
    },

    /**
     * Used to generate a query for the backend.
     */
    query: {
      required: true,
      type: Object
    }
  },

  /**
   * Functions that hang off the vue component instance. These are used to
   * navigate and manipulate state.
   */
  methods: {

    /**
     * The handler for click events on our search button. This function emits
     * search results as its state.
     */
    search: async function (_) {
      var json = await fetch(this.url).then(function(response) {
        return response.json();
      })

      this.$emit('search', json);
    },

    /**
     * The handler for click events on our reset button. Listeners for this 
     * event should clear their state.
     */
    reset: function (_) {
      this.$emit('reset', {})
    }
  }
}
</script>

