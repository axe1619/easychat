<script>
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
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
    requestAuthorization() {
      this.isRequestingAuthorization = true;
      useAlert(this.$t('INBOX_MGMT.ADD.INSTAGRAM.ERROR_AUTH'));
      this.isRequestingAuthorization = false;
    },
  },
};
</script>

<template>
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    :is-loading="isRequestingAuthorization"
    @reauthorize="requestAuthorization"
  />
</template>
