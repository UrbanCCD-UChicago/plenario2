<template>
  <section class="container full-page">
    <div class="row">
      <div class="col-12">
        <h2>View & Compare</h2>
      </div>
      <div class="col-12 col-md-7 col-lg-6">
        <p class="lead">Here's all the datasets Plenar.io found that match your search.</p>
        <p>
          Click on datasets to select them or deselect them, then click <kbd class="bg-light text-dark">Compare</kbd> to see what they
          look like together.
        </p>
      </div>
      <div class="col-12 col-md-5 col-lg-6 mb-3 mb-md-0">
        <div class="card card-outline-info">
          <div class="card-header bg-info text-white">
            <i class="fas fa-info-circle"></i>
            &ensp;Tips
          </div>
          <div class="card-body show" id="results-tip-body">
            <p class="card-text small text-muted">
              If you want to modify your search, scroll back up and tweak things (don't forget to click
              <kbd class="bg-light text-muted">Search</kbd> again!) or click <kbd class="bg-light text-muted">Reset</kbd> to
              start over.
            </p>
          </div>
        </div>
      </div>
    </div>
    <div id="results-tables-container">
      <div class="row">
        <div class="col-12">
          <h3 class="h5">Data From Open Data Providers</h3>
        </div>
      </div>
      <div id="searchResults">
        <div class="row">
          <div class="col-12">
            <table class="table table-sm mb-0">
              <thead class="thead-light">
                <th scope="col"></th>
                <th scope="col">Dataset Name</th>
                <th scope="col">Source</th>
              </thead>
              <tbody>
                <tr v-for="dataset in value.data" :key="dataset.slug" @click="toggle(dataset)">
                  <i v-if="selected.includes(dataset.name)" class="far fa-check-square"></i>
                  <i v-else class="far fa-square"></i>
                  <td>{{ dataset.name }}</td>
                  <td>{{ dataset.attribution }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <form class="row no-gutters form-inline py-2 mb-4 rounded-bottom bg-light results-table-footer" onsubmit="return false;" autocomplete="off">
          <label for="node-feature-data-search-term" class="sr-only">Filter</label>
          <div class="input-group input-group-sm col-8 pl-2">
            <div class="input-group-addon"><i class="fas fa-filter"></i></div>
            <input type="search" class="form-control" id="formGroupExampleInput2" placeholder="Filter...">
          </div>
          <div class="col-form-label-sm col-4 pr-2 text-muted text-right">
              {{ selected.length }}&thinsp;/&thinsp;{{ value.data.length }} selected
          </div>
        </form>
      </div>
    </div>
    <div class="col-12 px-0">
      <button id="compare-submit-button" type="button" class="btn btn-primary" @click="compare">
        Compare&emsp;<i class="fas fa-arrow-right"></i>
      </button>
    </div>
  </section>
</template>

<script>
export default {
  name: 'SearchResults',
  
  data: function () {
    return {
      selected: []
    }
  },

  props: {
    value: {
      required: true,
      type: Object
    },
  },

  methods: {

    /**
     * Adds a dataset id to the `selected` array. If the id is already in the
     * array, remove it.
     */
    toggle: function(dataset) {
      if (this.selected.includes(dataset.name)) {
        let index = this.selected.indexOf(dataset.name);
        this.selected.splice(index, 1);
      } 

      else {
        this.selected = this.selected.concat([dataset.name]);
      }
    },

    /**
     * Takes the slugs of datasets selected by the user and passes them along
     * to the comparison page.
     */
    compare: function(_) {
    }
  }
}
</script>

