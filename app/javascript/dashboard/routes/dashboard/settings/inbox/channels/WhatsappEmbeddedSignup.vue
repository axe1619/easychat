<script>
import { useAlert } from 'dashboard/composables';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import globalConstants from 'dashboard/constants/globals.js';
import {
  setupFacebookSdk,
  initWhatsAppEmbeddedSignup,
  createMessageHandler,
  isValidBusinessData,
} from './whatsapp/utils';

export default {
  components: {
    LoadingState,
  },
  data() {
    return {
      isProcessing: false,
      processingMessage: '',
      authCodeReceived: false,
      authCode: null,
      businessData: null,
      isAuthenticating: false,
      messageHandler: null,
    };
  },
  computed: {
    benefits() {
      return [
        {
          key: 'EASY_SETUP',
          text: this.$t(
            'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.EASY_SETUP'
          ),
        },
        {
          key: 'SECURE_AUTH',
          text: this.$t(
            'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.SECURE_AUTH'
          ),
        },
        {
          key: 'AUTO_CONFIG',
          text: this.$t(
            'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.AUTO_CONFIG'
          ),
        },
      ];
    },
    learnMoreHtml() {
      const linkText = this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LEARN_MORE.LINK_TEXT'
      );
      const linkHtml = `<a href="${globalConstants.WHATSAPP_EMBEDDED_SIGNUP_DOCS_URL}" target="_blank" rel="noopener noreferrer" class="underline text-woot-500 dark:text-woot-500">${linkText}</a>`;
      return this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LEARN_MORE.TEXT', {
        link: linkHtml,
      });
    },
    showLoader() {
      return this.isAuthenticating || this.isProcessing;
    },
  },
  created() {
    this.messageHandler = createMessageHandler(this.handleEmbeddedSignupData);
  },
  mounted() {
    this.setupMessageListener();
  },
  beforeDestroy() {
    this.cleanupMessageListener();
  },
  methods: {
    handleSignupError(data) {
      this.isProcessing = false;
      this.authCodeReceived = false;
      this.isAuthenticating = false;

      const errorMessage =
        data.error ||
        data.message ||
        this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
      useAlert(errorMessage);
    },
    handleSignupCancellation() {
      this.isProcessing = false;
      this.authCodeReceived = false;
      this.isAuthenticating = false;
    },
    handleSignupSuccess(inboxData) {
      this.isProcessing = false;
      this.isAuthenticating = false;

      if (inboxData && inboxData.id) {
        useAlert(this.$t('INBOX_MGMT.FINISH.MESSAGE'));
        this.$router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: inboxData.id,
          },
        });
      } else {
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUCCESS_FALLBACK'));
        this.$router.replace({
          name: 'settings_inbox_list',
        });
      }
    },
    async completeSignupFlow(businessDataParam) {
      if (!this.authCodeReceived || !this.authCode) {
        this.handleSignupError({
          error: this.$t(
            'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_NOT_COMPLETED'
          ),
        });
        return;
      }

      this.isProcessing = true;
      this.processingMessage = this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING'
      );

      try {
        const params = {
          code: this.authCode,
          business_id: businessDataParam.business_id,
          waba_id: businessDataParam.waba_id,
          phone_number_id: businessDataParam?.phone_number_id || '',
        };

        const responseData = await this.$store.dispatch(
          'inboxes/createWhatsAppEmbeddedSignup',
          params
        );

        this.authCode = null;
        this.handleSignupSuccess(responseData);
      } catch (error) {
        const errorMessage =
          parseAPIErrorResponse(error) ||
          this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
        this.handleSignupError({ error: errorMessage });
      }
    },
    async handleEmbeddedSignupData(data) {
      if (
        data.event === 'FINISH' ||
        data.event === 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING'
      ) {
        const businessDataLocal = data.data;

        if (isValidBusinessData(businessDataLocal)) {
          this.businessData = businessDataLocal;
          if (this.authCodeReceived && this.authCode) {
            await this.completeSignupFlow(businessDataLocal);
          } else {
            this.processingMessage = this.$t(
              'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_AUTH'
            );
          }
        } else {
          this.handleSignupError({
            error: this.$t(
              'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA'
            ),
          });
        }
      } else if (data.event === 'CANCEL') {
        this.handleSignupCancellation();
      } else if (data.event === 'error') {
        this.handleSignupError({
          error:
            data.error_message ||
            this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SIGNUP_ERROR'),
          error_id: data.error_id,
          session_id: data.session_id,
        });
      }
    },
    async launchEmbeddedSignup() {
      try {
        this.isAuthenticating = true;
        this.processingMessage = this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_PROCESSING'
        );

        await setupFacebookSdk(
          window.chatwootConfig?.whatsappAppId,
          window.chatwootConfig?.whatsappApiVersion
        );

        const code = await initWhatsAppEmbeddedSignup(
          window.chatwootConfig?.whatsappConfigurationId
        );

        this.authCode = code;
        this.authCodeReceived = true;
        this.processingMessage = this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_BUSINESS_INFO'
        );

        if (this.businessData) {
          this.completeSignupFlow(this.businessData);
        }
      } catch (error) {
        if (error.message === 'Login cancelled') {
          this.isProcessing = false;
          this.isAuthenticating = false;
          useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
        } else {
          this.handleSignupError({
            error:
              error.message ||
              this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SDK_LOAD_ERROR'),
          });
        }
      }
    },
    setupMessageListener() {
      if (!this.messageHandler) return;
      window.addEventListener('message', this.messageHandler);
    },
    cleanupMessageListener() {
      if (!this.messageHandler) return;
      window.removeEventListener('message', this.messageHandler);
    },
  },
};
</script>

<template>
  <div class="h-full">
    <LoadingState v-if="showLoader" :message="processingMessage" />

    <div v-else>
      <div class="flex flex-col items-start mb-6 text-start">
        <div class="flex justify-start mb-6">
          <div
            class="flex size-11 items-center justify-center rounded-full bg-slate-50 dark:bg-slate-800"
          >
            <img
              src="/assets/images/dashboard/channels/whatsapp.png"
              alt="WhatsApp"
              class="w-6 h-6"
            />
          </div>
        </div>

        <h3 class="mb-2 text-base font-medium text-slate-800 dark:text-slate-100">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.TITLE') }}
        </h3>
        <p class="text-sm leading-relaxed text-slate-700 dark:text-slate-300">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.DESC') }}
        </p>
      </div>

      <ul class="ml-5 list-disc flex flex-col gap-2 mb-6 text-sm text-slate-600 dark:text-slate-300">
        <li v-for="benefit in benefits" :key="benefit.key">
          {{ benefit.text }}
        </li>
      </ul>

      <div class="flex flex-col gap-2 mb-6">
        <span class="text-sm text-slate-600 dark:text-slate-300" v-html="learnMoreHtml"></span>
      </div>

      <div class="flex mt-4">
        <woot-button
          type="button"
          class="w-full"
          :is-loading="isAuthenticating"
          @click="launchEmbeddedSignup"
        >
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUBMIT_BUTTON') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
