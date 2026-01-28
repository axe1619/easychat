<script>
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import tiktokClient from 'dashboard/api/channel/tiktokClient';
import { useAlert } from 'dashboard/composables';

export default {
  components: {
    InboxReconnectionRequired,
  },
  data() {
    return {
      isRequestingAuthorization: false,
    };
  },
  methods: {
    async requestAuthorization() {
      try {
        this.isRequestingAuthorization = true;
        const response = await tiktokClient.generateAuthorization();

        const {
          data: { url },
        } = response;

        window.location.href = url;
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.TIKTOK.ERROR_AUTH'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>

<template>
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    @reauthorize="requestAuthorization"
  />
</template>
