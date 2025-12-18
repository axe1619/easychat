<script>
import { useAlert } from 'dashboard/composables';
import Icon from 'next/icon/Icon.vue';
import NextButton from 'next/button/Button.vue';
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
    Icon,
    NextButton,
    LoadingState,
  },
  data() {
    return {
      globalConstants,
      fbSdkLoaded: false,
      isProcessing: false,
      processingMessage: '',
      authCodeReceived: false,
      authCode: null,
      businessData: null,
      isAuthenticating: false,
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
    showLoader() {
      return this.isAuthenticating || this.isProcessing;
    },
    learnMoreParts() {
      const full = this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LEARN_MORE.TEXT'
      );
      const token = '{link}';
      if (full.includes(token)) {
        const [prefix, suffix] = full.split(token);
        return { prefix, suffix };
      }
      return { prefix: full, suffix: '' };
    },
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
    handleSignupMessage(data) {
      return this.handleEmbeddedSignupData(data);
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
        this.fbSdkLoaded = true;

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
              this.$t(
                'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SDK_LOAD_ERROR'
              ),
          });
        }
      }
    },
    setupMessageListener() {
      this._messageHandler = createMessageHandler(data =>
        this.handleEmbeddedSignupData(data)
      );
      window.addEventListener('message', this._messageHandler);
    },
    cleanupMessageListener() {
      if (this._messageHandler) {
        window.removeEventListener('message', this._messageHandler);
      }
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
          <div class="flex size-11 items-center justify-center rounded-full bg-n-alpha-2">
            <Icon icon="i-woot-whatsapp" class="text-n-slate-10 size-6" />
          </div>
        </div>

        <h3 class="mb-2 text-base font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.TITLE') }}
        </h3>
        <p class="text-sm leading-[24px] text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.DESC') }}
        </p>
      </div>

      <div class="flex flex-col gap-2 mb-6">
        <div
          v-for="benefit in benefits"
          :key="benefit.key"
          class="flex gap-2 items-center text-sm text-n-slate-11"
        >
          <Icon icon="i-lucide-check" class="text-n-slate-11 size-4" />
          {{ benefit.text }}
        </div>
      </div>

      <div class="flex flex-col gap-2 mb-6">
        <span class="text-sm text-n-slate-11">
          {{ learnMoreParts.prefix }}
          <a
            :href="globalConstants.WHATSAPP_EMBEDDED_SIGNUP_DOCS_URL"
            target="_blank"
            rel="noopener noreferrer"
            class="underline text-n-brand"
          >
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LEARN_MORE.LINK_TEXT') }}
          </a>
          {{ learnMoreParts.suffix }}
        </span>
      </div>

      <div class="flex mt-4">
        <NextButton
          :disabled="isAuthenticating"
          :is-loading="isAuthenticating"
          faded
          slate
          class="w-full"
          @click="launchEmbeddedSignup"
        >
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUBMIT_BUTTON') }}
        </NextButton>
      </div>
    </div>
  </div>
</template>
