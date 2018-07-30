<template>
  <div>
    <div class="form-group col-6 col-lg-12">
      <label for="starting_on">Starting On:</label>
      <input type="text" class="form-control" id="starting_on" name="starting_on" value="<%= @starts %>" placeholder="YYYY-MM-DD" required>
    </div>

    <div class="form-group col-6 col-lg-12">
      <label for="ending_on">Ending On:</label>
      <input type="text" class="form-control" id="ending_on" name="ending_on" value="<%= @ends %>" placeholder="YYYY-MM-DD" required>
    </div>

    <div class="form-group">
      <label for="granularity" class="control-label">Data Granularity:</label>
      <select id="granularity" name="granularity" class="form-control" value="<% @granularity %>" required>
        <option value="day">Day</option>
        <option value="week">Week</option>
        <option value="month">Month</option>
        <option value="year">Year</option>
      </select>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DatePicker'
}
</script>
 