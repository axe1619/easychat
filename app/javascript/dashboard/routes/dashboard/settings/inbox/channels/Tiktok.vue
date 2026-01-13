<script>
import tiktokClient from 'dashboard/api/channel/tiktokClient';

export default {
  data() {
    return {
      hasError: false,
      errorStateMessage: '',
      errorStateDescription: '',
      isRequestingAuthorization: false,
    };
  },
  mounted() {
    const urlParams = new URLSearchParams(window.location.search);
    const errorCode = urlParams.get('code');
    const errorMessage = urlParams.get('error_message');

    if (errorMessage) {
      this.hasError = true;
      if (errorCode === '400') {
        this.errorStateMessage = errorMessage;
        this.errorStateDescription = this.$t('INBOX_MGMT.ADD.TIKTOK.ERROR_AUTH');
      } else {
        this.errorStateMessage = this.$t('INBOX_MGMT.ADD.TIKTOK.ERROR_MESSAGE');
        this.errorStateDescription = errorMessage;
      }
    }
    const cleanURL = window.location.pathname;
    window.history.replaceState({}, document.title, cleanURL);
  },
  methods: {
    async requestAuthorization() {
      this.isRequestingAuthorization = true;
      try {
        const response = await tiktokClient.generateAuthorization();
        const {
          data: { url },
        } = response;

        window.location.href = url;
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>

<template>
  <div class="h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0">
    <div class="flex flex-col items-center justify-start h-full text-center">
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <div
        v-else
        class="flex flex-col items-center justify-center px-8 py-10 text-center rounded-2xl outline outline-1 outline-n-weak"
      >
        <h6 class="text-2xl font-medium">
          {{ $t('INBOX_MGMT.ADD.TIKTOK.CONNECT_YOUR_TIKTOK_PROFILE') }}
        </h6>
        <p class="py-6 text-sm text-slate-600 dark:text-slate-300">
          {{ $t('INBOX_MGMT.ADD.TIKTOK.HELP') }}
        </p>
        <woot-button
          class="text-white rounded-full px-6 bg-gradient-to-r from-[#00f2ea] via-[#ff0050] to-[#000000]"
          icon="i-ri-tiktok-line"
          :is-disabled="isRequestingAuthorization"
          :is-loading="isRequestingAuthorization"
          @click="requestAuthorization()"
        >
          {{ $t('INBOX_MGMT.ADD.TIKTOK.CONTINUE_WITH_TIKTOK') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
