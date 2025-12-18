<script>
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import whatsappChannel from 'dashboard/api/channel/whatsappChannel';
import { useAlert } from 'dashboard/composables';
import {
  setupFacebookSdk,
  initWhatsAppEmbeddedSignup,
  createMessageHandler,
  isValidBusinessData,
} from './utils';

export default {
  components: {
    InboxReconnectionRequired,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
    whatsappRegistrationIncomplete: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isRequestingAuthorization: false,
      isLoadingFacebook: true,
    };
  },
  computed: {
    whatsappAppId() {
      return window.chatwootConfig.whatsappAppId;
    },
    whatsappConfigurationId() {
      return window.chatwootConfig.whatsappConfigurationId;
    },
    actionLabel() {
      if (this.whatsappRegistrationIncomplete) {
        return this.$t('INBOX_MGMT.COMPLETE_REGISTRATION');
      }
      return '';
    },
    description() {
      if (this.whatsappRegistrationIncomplete) {
        return this.$t('INBOX_MGMT.WHATSAPP_REGISTRATION_INCOMPLETE');
      }
      return '';
    },
  },
  mounted() {
    this.initializeFacebookSdk();
  },
  methods: {
    async initializeFacebookSdk() {
      try {
        if (!this.whatsappAppId) {
          useAlert(this.$t('INBOX.REAUTHORIZE.WHATSAPP_APP_ID_MISSING'));
          return;
        }
        if (!this.whatsappConfigurationId) {
          useAlert(this.$t('INBOX.REAUTHORIZE.WHATSAPP_CONFIG_ID_MISSING'));
          return;
        }

        await setupFacebookSdk(
          this.whatsappAppId,
          window.chatwootConfig?.whatsappApiVersion
        );
      } catch (error) {
        useAlert(this.$t('INBOX.REAUTHORIZE.FACEBOOK_LOAD_ERROR'));
      } finally {
        this.isLoadingFacebook = false;
      }
    },
    async reauthorizeWhatsApp(params) {
      this.isRequestingAuthorization = true;

      try {
        const response = await whatsappChannel.reauthorizeWhatsApp({
          inboxId: this.inbox.id,
          ...params,
        });

        if (response.data.success) {
          useAlert(this.$t('INBOX.REAUTHORIZE.SUCCESS'));
        } else {
          useAlert(response.data.message || this.$t('INBOX.REAUTHORIZE.ERROR'));
        }
      } catch (error) {
        useAlert(error.message || this.$t('INBOX.REAUTHORIZE.ERROR'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
    async handleEmbeddedSignupEvents(data, authCode) {
      if (!data || typeof data !== 'object') {
        return;
      }

      if (data.event === 'FINISH') {
        const businessData = data.data;

        if (isValidBusinessData(businessData) && businessData.phone_number_id) {
          await this.reauthorizeWhatsApp({
            code: authCode,
            business_id: businessData.business_id,
            waba_id: businessData.waba_id,
            phone_number_id: businessData.phone_number_id,
          });
        } else {
          useAlert(
            this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA')
          );
        }
      } else if (data.event === 'CANCEL') {
        this.isRequestingAuthorization = false;
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
      } else if (data.event === 'error') {
        this.isRequestingAuthorization = false;
        useAlert(
          data.error_message ||
            this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SIGNUP_ERROR')
        );
      }
    },
    startEmbeddedSignup(authCode) {
      const messageHandler = createMessageHandler(data =>
        this.handleEmbeddedSignupEvents(data, authCode)
      );
      window.addEventListener('message', messageHandler);
    },
    async handleLoginAndReauthorize() {
      if (!this.whatsappAppId) {
        throw new Error('WhatsApp App ID is required');
      }
      if (!this.whatsappConfigurationId) {
        throw new Error('WhatsApp Configuration ID is required');
      }

      const authCode = await initWhatsAppEmbeddedSignup(
        this.whatsappConfigurationId
      );

      const existingConfig = this.inbox.provider_config;
      if (
        existingConfig &&
        existingConfig.business_account_id &&
        existingConfig.phone_number_id
      ) {
        await this.reauthorizeWhatsApp({
          code: authCode,
          business_id: existingConfig.business_account_id,
          waba_id: existingConfig.business_account_id,
          phone_number_id: existingConfig.phone_number_id,
        });
      } else {
        this.startEmbeddedSignup(authCode);
      }
    },
    async requestAuthorization() {
      if (this.isLoadingFacebook) {
        useAlert(this.$t('INBOX.REAUTHORIZE.LOADING_FACEBOOK'));
        return;
      }

      this.isRequestingAuthorization = true;
      try {
        await this.handleLoginAndReauthorize();
      } catch (error) {
        useAlert(error.message || this.$t('INBOX.REAUTHORIZE.CONFIGURATION_ERROR'));
      } finally {
        if (!window.FB || !window.FB.getLoginStatus) {
          this.isRequestingAuthorization = false;
        }
      }
    },
  },
};
</script>

<template>
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    :is-loading="isRequestingAuthorization"
    :action-label="actionLabel"
    :description="description"
    @reauthorize="requestAuthorization"
  />
</template>
