<script>
import { mapGetters } from 'vuex';
import Thumbnail from '../../widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserAvailability: 'getCurrentUserAvailability',
    }),
    statusOfAgent() {
      return this.currentUserAvailability || 'offline';
    },
  },
  methods: {
    handleClick() {
      this.$emit('toggleMenu');
    },
  },
};
</script>

<template>
  <woot-button
    v-tooltip.right="{
      content: $t(`SIDEBAR.PROFILE_SETTINGS`),
      container: 'body',
      popperOptions: {
        modifiers: {
          offset: { offset: '0, 0' },
          flip: { enabled: false },
          preventOverflow: { enabled: true,  boundariesElement: 'viewport'},
        },
      },
    }"
    variant="link"
    class="flex items-center rounded-full"
    @click="handleClick"
  >
    <Thumbnail
      :src="currentUser.avatar_url"
      :username="currentUser.name"
      :status="statusOfAgent"
      should-show-status-always
      size="32px"
    />
  </woot-button>
</template>
