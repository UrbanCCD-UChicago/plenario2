<template>
  <!-- At large screen size, we break the instructions out into their own card-->
  <div class="col-lg-4 d-none d-lg-block float-lg-left pr-lg-1">
    <div class="card space-card">
      <div class="card-header">
        <i class="far fa-compass">
        </i>
        &ensp;Space
      </div>
      <div class="card-body">
        <p class="card-text">
          Use the draw controls on the map to draw a shape.
        </p>
        <p class="card-text text-muted small">
          If you draw a line, Plenar.io will search near it. If you draw a closed shape, Plenar.io will search
          within that shape.
        </p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SpaceSearch'
}
</script>
