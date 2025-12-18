<script>
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import googleClient from 'dashboard/api/channel/googleClient';
import { useAlert } from 'dashboard/composables';

export default {
  components: {
    InboxReconnectionRequired,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isRequestingAuthorization: false,
    };
  },
  computed: {
    inboxEmail() {
      if (this.inbox.imap_login && this.inbox.imap_enabled) {
        return this.inbox.imap_login;
      }
      return this.inbox.email;
    },
  },
  methods: {
    async requestAuthorization() {
      try {
        this.isRequestingAuthorization = true;
        const response = await googleClient.generateAuthorization({
          email: this.inboxEmail,
        });

        const {
          data: { url },
        } = response;
        window.location.href = url;
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.GOOGLE.ERROR_MESSAGE'));
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
    :is-loading="isRequestingAuthorization"
    @reauthorize="requestAuthorization"
  />
</template>
