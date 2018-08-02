<template>
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
            <button type="button" class="btn btn-danger">
              <i class="fas fa-undo"></i>
              Reset
            </button>
          </div>
          <div class="col-6 col-md-3 col-xl-6 pl-1">
            <button type="button" class="btn btn-primary">
              <i class="fas fa-search"></i>
              Search
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>


<script>
export default {
  name: 'ActionCard'
}
</script>
