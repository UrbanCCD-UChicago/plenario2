<template>
  <tr>
    <th scope="row">
      <self-building-square-spinner 
        v-if="!loaded"
        :animation-duration="6000"
        :size="20"
        color="#ff1d5e"
      />
      <FontAwesomeIcon v-else-if="!active" icon="toggle-off" />
      <FontAwesomeIcon v-else icon="toggle-on" />
    </th>
    <td>{{ slug }}</td>
    <td>
      <self-building-square-spinner 
        v-if="!loaded"
        :animation-duration="6000"
        :size="20"
        color="#ff1d5e"
      />
      <div v-else>{{ count }} rows</div>
    </td>
  </tr>
</template>

<script>
import { SelfBuildingSquareSpinner } from 'epic-spinners'

export default {
  data: function () {
    return {
      active: false,
      loaded: false,
      count: 0
    };
  },

  props: {
    slug: {
      type: String
    }
  },

  components: {
    SelfBuildingSquareSpinner
  }
}
</script>
