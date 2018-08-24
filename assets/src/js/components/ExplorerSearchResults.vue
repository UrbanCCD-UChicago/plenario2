<template>
  <section class="container full-page">
    <div class="row">
      <div class="col-12">
        <h2>View & Compare</h2>
      </div>
      <div class="col-12 col-md-7 col-lg-6">
        <p class="lead">Here's all the datasets Plenar.io found that match your search.</p>
        <p>
          Click on datasets to select them or deselect them, then click <kbd class="bg-light
          text-dark">Compare</kbd> to see what they look like together.
        </p>
      </div>
      <div class="col-12 col-md-5 col-lg-6 mb-3 mb-md-0">
        <div class="card card-outline-info">
          <div class="card-header bg-info text-white">
            <FontAwesomeIcon icon="info-circle" />
            &ensp;Tips
          </div>
          <div id="results-tip-body"
               class="card-body show">
            <p class="card-text small text-muted">
              If you want to modify your search, scroll back up and tweak things (don't forget to
              click
              <kbd class="bg-light text-muted">Search</kbd> again!) or click
              <kbd class="bg-light text-muted">Reset</kbd> to start over.
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
                <tr v-for="dataset in filteredDatasets"
                    :key="dataset.slug"
                    @click="toggle(dataset)">
                  <td>
                    <FontAwesomeIcon v-if="selected.includes(dataset.slug)"
                                     icon="check-square" />
                    <FontAwesomeIcon v-else
                                     :icon="['far', 'square']" />
                  </td>
                  <td>{{ dataset.name }}</td>
                  <td>{{ dataset.attribution }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <form class="row no-gutters form-inline py-2 mb-4 bg-light"
              onsubmit="return false;"
              autocomplete="off">
          <label for="node-feature-data-search-term"
                 class="sr-only">
            Filter
          </label>
          <div class="input-group input-group-sm col-8 pl-2">
            <div class="input-group-addon">
              <FontAwesomeIcon icon="filter" />
            </div>
            <input id="formGroupExampleInput2"
                   v-model="filterString"
                   type="search"
                   class="form-control"
                   placeholder="">
          </div>
          <div class="col-form-label-sm col-4 pr-2 text-muted text-right">
            {{ selected.length }}&thinsp;/&thinsp;{{ value.length }} selected
          </div>
        </form>
      </div>
    </div>
    <div class="col-12 px-0">
      <router-link to="/compare"
                   tag="button"
                   class="btn btn-primary btn-block">
        Compare
      </router-link>
    </div>
  </section>
</template>

<script>
export default {
  name:  'ExplorerSearchResults',
  props: {
    value: { type: Array, required: true },
  },
  data: () => ({
    selected:     [],
    filterString: '',
  }),
  computed: {
    filteredDatasets() {
      return this.value
        .filter(dataset => dataset.name.includes(this.filterString));
    },
  },
  methods: {
    /**
     * Adds a dataset id to the `selected` array. If the id is already in the
     * array, remove it.
     */
    toggle(dataset) {
      if (this.selected.includes(dataset.slug)) {
        const index = this.selected.indexOf(dataset.slug);
        this.selected.splice(index, 1);
      } else {
        this.selected = this.selected.concat([dataset.slug]);
      }
    },
  },

  watch: {
    selected: function () {
      this.$store.commit('setSelectedDatasets', this.selected);
    }
  }
}
</script>

