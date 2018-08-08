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
      <div id="searchResults"></div>
    </div>
    <div class="col-12 px-0">
      <button id="compare-submit-button" type="primary" block=true>
        Compare&emsp;<i class="fas fa-arrow-right"></i>
      </button>
    </div>
  </section>
</template>

<script>
export default {
  name: 'SearchResults',
  props: {
    value: {
      required: true,
      type: Object
    }
  }
}
</script>

