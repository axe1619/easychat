<script>
export default {
  props: {
    inbox: {
      type: Object,
      required: true,
    },
    inboxId: {
      type: [String, Number],
      required: true,
    },
  },
  computed: {
    message() {
      return this.inbox.forwarding_enabled
        ? this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE')
        : this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE_NO_FORWARDING');
    },
    showForwardingAddress() {
      return this.inbox.forwarding_enabled;
    },
  },
};
</script>

<template>
  <div class="w-full text-center">
    <p class="text-base text-n-slate-11 mt-4 w-4/5 mx-auto leading-7">
      {{ message }}
    </p>

    <div v-if="showForwardingAddress" class="w-[50%] max-w-[50%] mx-auto">
      <p class="mt-8 mb-4 font-medium text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FORWARDING_ADDRESS_LABEL') }}
      </p>
      <woot-code lang="html" :script="inbox.forward_to_email" />
    </div>

    <p class="mt-8 text-sm text-n-slate-11 pb-4">
      <router-link
        :to="{
          name: 'settings_inbox_show',
          params: { inboxId: inboxId, tab: 'configuration' },
        }"
        class="text-n-woot-600 hover:text-n-woot-700 underline"
      >
        {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CONFIGURE_SMTP_IMAP_LINK') }}
      </router-link>
      {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CONFIGURE_SMTP_IMAP_TEXT') }}
    </p>
  </div>
</template>
