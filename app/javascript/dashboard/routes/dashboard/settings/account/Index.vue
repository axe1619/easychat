<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minValue, maxValue } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import semver from 'semver';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import wootConstants from 'dashboard/constants/globals';
import SwitchButton from "dashboard/components/ui/Switch.vue";

export default {
  components: {
    SwitchButton
  },
  setup() {
    const { updateUISettings } = useUISettings();
    const { enabledLanguages } = useConfig();
    const v$ = useVuelidate();

    return { updateUISettings, v$, enabledLanguages };
  },
  data() {
    return {
      id: '',
      name: '',
      locale: 'en',
      file:'',
      logoUrl:'',
      domain: '',
      supportEmail: '',
      features: {},
      autoResolveDuration: null,
      latestChatwootVersion: null,
      disableBotAgentReply: false
    };
  },
  validations: {
    name: {
      required,
    },
    locale: {
      required,
    },
    autoResolveDuration: {
      minValue: minValue(1),
      maxValue: maxValue(999),
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    showAutoResolutionConfig() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.AUTO_RESOLVE_CONVERSATIONS
      );
    },
    hasAnUpdateAvailable() {
      if (!semver.valid(this.latestChatwootVersion)) {
        return false;
      }

      return semver.lt(
        this.globalConfig.appVersion,
        this.latestChatwootVersion
      );
    },
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },

    featureInboundEmailEnabled() {
      return !!this.features?.inbound_emails;
    },

    featureCustomReplyDomainEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_domain
      );
    },

    featureCustomReplyEmailEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_email
      );
    },

    getAccountId() {
      return this.id.toString();
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const {
          name,
          logo,
          locale,
          id,
          domain,
          support_email,
          features,
          auto_resolve_duration,
          disable_bot_on_agent_reply,
          latest_chatwoot_version: latestChatwootVersion,
        } = this.getAccount(this.accountId);

        this.$root.$i18n.locale = locale;
        this.name = name;
        this.logoUrl = logo ?? '';
        this.locale = locale;
        this.id = id;
        this.domain = domain;
        this.supportEmail = support_email;
        this.features = features;
        this.autoResolveDuration = auto_resolve_duration;
        this.latestChatwootVersion = latestChatwootVersion;
        this.disableBotAgentReply = disable_bot_on_agent_reply;
      } catch (error) {
        // Ignore error
      }
    },

    async updateAccount() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        const formData = new FormData()
        const data = {
          locale: this.locale,
          name: this.name,
          domain: this.domain,
          logo: this.file,
          support_email: this.supportEmail,
          auto_resolve_duration: this.autoResolveDuration,
          disable_bot_on_agent_reply: this.disableBotAgentReply
        }
        for (const [key, value] of Object.entries(data)) {
          if (value !== undefined && value !== null && value !== '') 
            formData.append(key, value)
        }
        await this.$store.dispatch('accounts/update', formData);
        this.$root.$i18n.locale = this.locale;
        this.getAccount(this.id).locale = this.locale;
        this.updateDirectionView(this.locale);
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },

    updateDirectionView(locale) {
      const isRTLSupported = getLanguageDirection(locale);
      this.updateUISettings({
        rtl_view: isRTLSupported,
      });
    },
    loadImagenDefault(event){
        event.target.src = wootConstants.DEFAULT_LOGO
    },
    onChangeLogo(event) {
      try {
        this.file = event.target.files[0]
        if(!this.file) return
        const reader = new FileReader();
        reader.onload = e => {
          this.logoUrl = e.target.result;
        };
        reader.readAsDataURL(this.file);
      } catch (error) {
        console.warn({ error })
      }
    },
    onSwitchAgentBotReply(value){
      this.disableBotAgentReply = value
    }
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto">
    <form v-if="!uiFlags.isFetchingItem" @submit.prevent="updateAccount">
      <div 
        class="flex mx-auto flex-column flex-wrap w-[70%] border-b border-slate-25 dark:border-slate-800"
        >
        <div 
          class="w-full"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.TITLE') }}
          </h4>
          <p>{{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.NOTE') }}</p>
        </div>
        <div class="w-full">
          <div class="flex gap-5">
            <div class="flex flex-col justify-start gap-1">
              <label>{{ $t('GENERAL_SETTINGS.LOGO') }}</label>
              <label for="id-logo" class="content-logo">
                <img @error="loadImagenDefault" class="logo" :src="logoUrl" alt="logo company" />
                <input id="id-logo" @change="onChangeLogo"  accept="image/*" type="file" class="hidden" />
              </label>
            </div>
            <div class="flex-1">
              <label :class="{ error: v$.name.$error }">
                {{ $t('GENERAL_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="$t('GENERAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @blur="v$.name.$touch"
            />
                <span v-if="v$.name.$error" class="message">
                  {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
                </span>
              </label>
              <label :class="{ error: v$.locale.$error }">
                {{ $t('GENERAL_SETTINGS.FORM.LANGUAGE.LABEL') }}
                <select v-model="locale">
              <option
                v-for="lang in languagesSortedByCode"
                :key="lang.iso_639_1_code"
                :value="lang.iso_639_1_code"
              >
                    {{ lang.name }}
                  </option>
                </select>
                <span v-if="v$.locale.$error" class="message">
                  {{ $t('GENERAL_SETTINGS.FORM.LANGUAGE.ERROR') }}
                </span>
              </label>
            </div>
          </div>
          <div class="flex justify-between mt-2 mb-4">
            <label>{{ $t('GENERAL_SETTINGS.FORM.DISABLE_AGENT_BOT_REPLY.LABEL') }}</label>
            <SwitchButton
              :value="disableBotAgentReply"
              @input="onSwitchAgentBotReply"
            />
          </div>
          <label v-if="featureInboundEmailEnabled">
            {{ $t('GENERAL_SETTINGS.FORM.FEATURES.INBOUND_EMAIL_ENABLED') }}
          </label>
          <label v-if="featureCustomReplyDomainEnabled">
            {{
            $t('GENERAL_SETTINGS.FORM.FEATURES.CUSTOM_EMAIL_DOMAIN_ENABLED')
            }}
          </label>
          <label v-if="featureCustomReplyDomainEnabled">
            {{ $t('GENERAL_SETTINGS.FORM.DOMAIN.LABEL') }}
            <input
              v-model="domain"
              type="text"
              :placeholder="$t('GENERAL_SETTINGS.FORM.DOMAIN.PLACEHOLDER')"
            />
          </label>
          <label v-if="featureCustomReplyEmailEnabled">
            {{ $t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.LABEL') }}
            <input
              v-model="supportEmail"
              type="text"
              :placeholder="
                $t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.PLACEHOLDER')
              "
            />
          </label>
          <label
            v-if="showAutoResolutionConfig"
            :class="{ error: v$.autoResolveDuration.$error }"
          >
            {{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.LABEL') }}
            <input
              v-model="autoResolveDuration"
              type="number"
              :placeholder="
                $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.PLACEHOLDER')
              "
              @blur="v$.autoResolveDuration.$touch"
            />
            <span v-if="v$.autoResolveDuration.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.ERROR') }}
            </span>
          </label>
        </div>
      </div>

      <div
        class="flex mx-auto flex-column flex-wrap w-[70%] border-slate-25 dark:border-slate-700 text-black-900 dark:text-slate-300"
        >
        <div class="w-full">
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.TITLE') }}
          </h4>
          <p>
            {{ $t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.NOTE') }}
          </p>
        </div>
        <div class="w-full">
          <woot-code :script="getAccountId" />
        </div>
      </div>
      <div class="p-4 text-sm text-center">
        <div>{{ `v${globalConfig.appVersion}` }}</div>
        <div v-if="hasAnUpdateAvailable && globalConfig.displayManifest">
          {{
            $t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
              latestChatwootVersion: latestChatwootVersion,
            })
          }}
        </div>
        <div class="build-id">
          <div>{{ `Build ${globalConfig.gitSha}` }}</div>
        </div>
      </div>

      <woot-submit-button
        class="button nice success button--fixed-top"
        :button-text="$t('GENERAL_SETTINGS.SUBMIT')"
        :loading="isUpdating"
      />
    </form>

    <woot-loading-state v-if="uiFlags.isFetchingItem" />
  </div>
</template>
<style>
  .content-logo{
    display: flex;
    flex-direction: column;
    width: 200px;
    height: 120px;
    object-fit: cover;
    border: 1px dashed #808080cc;
    border-radius: 5px;
    cursor: pointer;
    justify-content: center;
    align-items: center;
    padding: 0 5px;
  }
  .logo{
    height: 80%;
    border-radius: 5px;
  }
</style>
