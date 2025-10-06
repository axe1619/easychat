<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import ImapSettings from '../ImapSettings.vue';
import SmtpSettings from '../SmtpSettings.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, numeric, minValue, maxValue } from '@vuelidate/validators';

export default {
  components: {
    SettingsSection,
    ImapSettings,
    SmtpSettings,
  },
  mixins: [inboxMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      hmacMandatory: false,
      whatsAppInboxAPIKey: '',
      countMessageSorter: 1,
      selectedSorters: [],
      loading: {
        sorter: false
      }
    };
  },
  validations() {
    return {
      countMessageSorter: {
        required,
        minValue: minValue(1),
        maxValue: maxValue(20),
        numeric
      },
      selectedSorters: {
        required,
      },
      whatsAppInboxAPIKey: {
        required: this.isAWhatsAppChannel
      },
    }
  },
  computed: {
    ...mapGetters({
      sorters: 'sorter/getSorters',
    }),
    messageErrorSelectedSorter() {
      const field = this.v$.selectedSorters
      if (field.required.$invalid)
        return this.$t("INBOX_MGMT.SORTER.REQUIRED");
    },
    messageErrorCountMessageSorter() {
      const field = this.v$.countMessageSorter
      if (field.minValue.$invalid || field.maxValue.$invalid) {
        return this.$t("INBOX_MGMT.SORTER.SIZE", {
          MIN: field.minValue.$params.min,
          MAX: field.maxValue.$params.max
        });
      }
    },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
    this.$store.dispatch('sorter/get')
  },
  methods: {
    setDefaults() {
      this.hmacMandatory = this.inbox.hmac_mandatory || false;
      this.countMessageSorter = this.inbox.count_reload_conversation_state || 1
      this.selectedSorters = this.inbox.conversation_states
    },
    handleHmacFlag() {
      this.updateInbox();
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            hmac_mandatory: this.hmacMandatory,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateWhatsAppInboxAPIKey() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {},
        };

        payload.channel.provider_config = {
          ...this.inbox.provider_config,
          api_key: this.whatsAppInboxAPIKey,
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    onUpdateSorter() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.loading.sorter = true
      this.$store.dispatch('inboxes/updateConvesationStates', {
        inbox_id: this.inbox.id,
        count_reload_conversation_state: this.countMessageSorter,
        conversation_states: this.selectedSorters
      }).then(() => {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }).catch(() => {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }).finally(() => {
        this.loading.sorter = false
      })
    }
  },
};
</script>

<template>
  <div>
    <div class="mx-8">
      <SettingsSection
          :title="$t('INBOX_MGMT.SORTER.TITLE')"
          :sub-title="$t('INBOX_MGMT.SORTER.DESCRIPTION')"
        >
        <div class="flex gap-3">
          <div class="w-full">
            <small>{{ $t("INBOX_MGMT.SORTER.FORM.LABEL_SELECT") }}</small>
            <multiselect
              v-model="selectedSorters"
              :options="sorters"
              track-by="id"
              label="name"
              multiple
              hide-selected
              :close-on-select="false"
              :clear-on-select="false"
              selected-label
              :class="{ error: v$.selectedSorters.$error }"
            />
            <small>{{ messageErrorSelectedSorter }}</small>
          </div>
          <div>
            <small>{{ $t("INBOX_MGMT.SORTER.FORM.LABEL_COUNT_MESSAGE") }}</small>
            <woot-input 
              v-model="countMessageSorter" 
              type="number" 
              class="mt-1"
              :class="{ error: v$.countMessageSorter.$error }"
            />
            <small>{{ messageErrorCountMessageSorter }}</small>
          </div>
        </div>
        <div class="mt-2">
          <woot-button :is-loading="loading.sorter" @click="onUpdateSorter" type="button">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.UPDATE') }} 
          </woot-button>
        </div>
      </SettingsSection>
    </div>
    <div v-if="isATwilioChannel" class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
        :sub-title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
      >
        <woot-code :script="inbox.callback_webhook_url" lang="html" />
      </SettingsSection>
    </div>
    <div v-else-if="isALineChannel" class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.TITLE')"
        :sub-title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE')"
      >
        <woot-code :script="inbox.callback_webhook_url" lang="html" />
      </SettingsSection>
    </div>
    <div v-else-if="isAWebWidgetInbox">
      <div class="mx-8">
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
        >
          <woot-code
            :script="inbox.web_widget_script"
            lang="html"
            :codepen-title="`${inbox.name} - Chatwoot Widget Test`"
            enable-code-pen
          />
        </SettingsSection>

        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
        >
          <woot-code :script="inbox.hmac_token" />
          <template #subTitle>
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION') }}
            <a
              target="_blank"
              rel="noopener noreferrer"
              href="https://www.chatwoot.com/docs/product/channels/live-chat/sdk/identity-validation/"
            >
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_LINK_TO_DOCS') }}
            </a>
          </template>
        </SettingsSection>
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
        >
          <div class="flex items-center gap-2">
            <input
              id="hmacMandatory"
              v-model="hmacMandatory"
              type="checkbox"
              @change="handleHmacFlag"
            />
            <label for="hmacMandatory">
              {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
            </label>
          </div>
        </SettingsSection>
      </div>
    </div>
    <div v-else-if="isAPIInbox" class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER_SUB_TEXT')"
      >
        <woot-code :script="inbox.inbox_identifier" />
      </SettingsSection>

      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION')"
      >
        <woot-code :script="inbox.hmac_token" />
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
      >
        <div class="flex items-center gap-2">
          <input
            id="hmacMandatory"
            v-model="hmacMandatory"
            type="checkbox"
            @change="handleHmacFlag"
          />
          <label for="hmacMandatory">
            {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
          </label>
        </div>
      </SettingsSection>
    </div>
    <div v-else-if="isAnEmailChannel">
      <div class="mx-8">
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_TITLE')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_SUB_TEXT')"
        >
          <woot-code :script="inbox.forward_to_email" />
        </SettingsSection>
      </div>
      <ImapSettings :inbox="inbox" />
      <SmtpSettings v-if="inbox.imap_enabled" :inbox="inbox" />
    </div>
    <div v-else-if="isAWhatsAppChannel && !isATwilioChannel">
      <div v-if="inbox.provider_config" class="mx-8">
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_TITLE')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_SUBHEADER')"
        >
          <woot-code :script="inbox.provider_config.webhook_verify_token" />
        </SettingsSection>
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')"
        >
          <woot-code :script="inbox.provider_config.api_key" />
        </SettingsSection>
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_TITLE')"
          :sub-title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_SUBHEADER')
          "
        >
          <div
            class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
          >
            <woot-input
              v-model.trim="whatsAppInboxAPIKey"
              type="text"
              class="flex-1 mr-2"
              :placeholder="
                $t(
                  'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_PLACEHOLDER'
                )
              "
            />
            <woot-button
              :disabled="v$.whatsAppInboxAPIKey.$invalid"
              @click="updateWhatsAppInboxAPIKey"
            >
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
            </woot-button>
          </div>
        </SettingsSection>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.whatsapp-settings--content {
  ::v-deep input {
    margin-bottom: 0;
  }
}
</style>
