<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import campaignMixin from 'shared/mixins/campaignMixin';
import WootDateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import { URLPattern } from 'urlpattern-polyfill';
import { CAMPAIGNS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import { INBOX_TYPES } from 'shared/mixins/inboxMixin';
import WhatsappTemplates from '../../conversation/contact/WhatsappTemplates.vue';
export default {
  components: {
    WootDateTimePicker,
    WootMessageEditor,
    WhatsappTemplates
  },
  mixins: [campaignMixin],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    const listDesign = {
      DEFAULT: "DEFAULT",
      WHATSAPP: "WHATSAPP"
    };
    return {
      title: '',
      message: '',
      additional_attributes: {},
      selectedSender: undefined,
      selectedInbox: null,
      endPoint: '',
      timeOnPage: 10,
      show: true,
      enabled: true,
      triggerOnlyDuringBusinessHours: false,
      scheduledAt: null,
      selectedAudience: [],
      senderList: [],
      listDesign,
      design: listDesign.DEFAULT,
      template: undefined
    };
  },

  validations() {
    const commonValidations = {
      title: {
        required,
      },
      message: {
        required,
      },
      selectedInbox: {
        required,
      },
      selectedSender: {
          required,
       },
    };
    if (this.isOngoingType) {
      return {
        ...commonValidations,
        endPoint: {
          required,
          shouldBeAValidURLPattern(value) {
            try {
              // eslint-disable-next-line
              new URLPattern(value);
              return true;
            } catch (error) {
              return false;
            }
          },
          shouldStartWithHTTP(value) {
            if (value) {
              return (
                value.startsWith('https://') || value.startsWith('http://')
              );
            }
            return false;
          },
        },
        timeOnPage: {
          required,
        },
      };
    }
    return {
      ...commonValidations,
      scheduledAt: {
        required
      },
      selectedAudience: {
        isEmpty() {
          return !!this.selectedAudience.length;
        },
      },
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
      audienceList: 'labels/getLabels',
    }),
    inboxes() {
      if (this.isOngoingType) {
        return this.$store.getters['inboxes/getWebsiteInboxes'];
      }
      return this.$store.getters['inboxes/getEnabledInboxes'];
    },
    sendersAndBotList() {
      if (this.isOngoingType) {
        return [
          {
            id: 0,
            name: 'Bot',
          },
          ...this.senderList,
        ];
      }
      return [
        ...this.senderList,
      ];
    },
    isEnabledSelectedSender() {
      let selectedInbox = this.inboxes.find((inbox) => inbox.id == this.selectedInbox)
      if (!selectedInbox) return false
      const enabledTypes = [INBOX_TYPES.WHATSAPP]
      return enabledTypes.includes(selectedInbox.channel_type)
    }
  },
  watch: {
    sendersAndBotList(value) {
      this.setSender(value)
    }
  },
  mounted() {
    this.$track(CAMPAIGNS_EVENTS.OPEN_NEW_CAMPAIGN_MODAL, {
      type: this.campaignType,
    });
    this.setSender(this.sendersAndBotList)
  },
  methods: {
    onClose() {
      this.$emit('onClose');
    },
    onChange(value) {
      this.scheduledAt = value;
    },
    async onChangeInbox() {
      this.loadSenderList()
      this.adaptDesignForm()
    },
    getCampaignDetails() {
      let campaignDetails = null;
      if (this.isOngoingType) {
        campaignDetails = {
          title: this.title,
          message: this.message,
          inbox_id: this.selectedInbox,
          sender_id: this.selectedSender || null,
          enabled: this.enabled,
          trigger_only_during_business_hours:
            // eslint-disable-next-line prettier/prettier
            this.triggerOnlyDuringBusinessHours,
          trigger_rules: {
            url: this.endPoint,
            time_on_page: this.timeOnPage,
          },
        };
      } else {
        const audience = this.selectedAudience.map(item => {
          return {
            id: item.id,
            type: 'Label',
          };
        });
        campaignDetails = {
          title: this.title,
          message: this.message,
          sender_id: this.selectedSender || null,
          inbox_id: this.selectedInbox,
          scheduled_at: this.scheduledAt,
          audience,
          additional_attributes: this.getAdditionalAttributes(this.selectedInbox)
        };
      }
      return campaignDetails;
    },
    async addCampaign() {
      if (!await this.validateForm())
        return
      try {
        const campaignDetails = this.getCampaignDetails();
        await this.$store.dispatch('campaigns/create', campaignDetails);

        // tracking this here instead of the store to track the type of campaign
        this.$track(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
          type: this.campaignType,
        });
        this.message = ""
        useAlert(this.$t('CAMPAIGN.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
    async validateForm() {
      let subFormValidate
      switch (this.design) {
        case this.listDesign.WHATSAPP:
          subFormValidate = await this.validateTemplateWhatsapp()
          break
        default:
          break
      }
      this.v$.$touch();
      return subFormValidate && !this.v$.$invalid
    },
    async validateTemplateWhatsapp() {
      const whatsappCmp = this.$refs.whatsappTemplate;
      if (!whatsappCmp.validateTemplate()) return false;
      this.template = await whatsappCmp.getTemplateMessage();
      this.message = this.template.message;
      return true;
    },
    async loadSenderList() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.selectedInbox,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        this.senderList = inboxMembers;
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
    getAdditionalAttributes(inboxId) {
      let selectedInbox = this.inboxes.find((inbox) => inbox.id == inboxId)
      if (!selectedInbox || !this.template) {
        return {}
      }
      if (selectedInbox.channel_type == INBOX_TYPES.WHATSAPP) {
        const { templateParams } = this.template
        let template = {
          template_params: {
            name: templateParams.name,
            category: templateParams.category,
            language: templateParams.language,
            processed_params: templateParams.processed_params
          }
        }
        if (templateParams.header) {
          template.template_params.header = templateParams.header
        }
        return template
      }
      return {}
    },
    adaptDesignForm() {
      let selectedInbox = this.inboxes.find((inbox) => inbox.id == this.selectedInbox)
      if (!selectedInbox) {
        this.design = this.listDesign.DEFAULT
        return
      }
      if (selectedInbox.channel_type == INBOX_TYPES.WHATSAPP) {
        this.design = this.listDesign.WHATSAPP
        return
      }
       this.design = this.listDesign.DEFAULT
    },
    setSender(list){
      if (!Array.isArray(list) || list.length == 0) {
        return
      }
      this.selectedSender = list[0].id
    }
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('CAMPAIGN.ADD.TITLE')"
      :header-content="$t('CAMPAIGN.ADD.DESC')"
    />
    <form class="flex flex-col w-full" @submit.prevent="addCampaign">
      <div class="w-full">
        <woot-input
          v-model="title"
          :label="$t('CAMPAIGN.ADD.FORM.TITLE.LABEL')"
          type="text"
          :class="{ error: v$.title.$error }"
          :error="v$.title.$error ? $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') : ''"
          :placeholder="$t('CAMPAIGN.ADD.FORM.TITLE.PLACEHOLDER')"
          @blur="v$.title.$touch"
        />

        <label :class="{ error: v$.selectedInbox.$error }">
          {{ $t('CAMPAIGN.ADD.FORM.INBOX.LABEL') }}
          <select v-model="selectedInbox" @change="onChangeInbox($event)">
            <option v-for="item in inboxes" :key="item.name" :value="item.id">
              {{ item.name }}
            </option>
          </select>
          <span v-if="v$.selectedInbox.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.INBOX.ERROR') }}
          </span>
        </label>
        
        <template v-if="design==listDesign.WHATSAPP">
          <label>
            Templates whatsapp 
            <small class="font-medium text-gray">
              ( Las plantillas nuevas puede tomar alrededor de 1hr en ser aceptadas )
            </small>
          </label>
          <WhatsappTemplates
            ref="whatsappTemplate"
            :inbox-id="selectedInbox"
            :showButtonAction="false"
          />
        </template>
        <template v-else>
          <div v-if="isOngoingType" class="editor-wrap">
            <label>
              {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.LABEL') }}
            </label>
            <div>
              <WootMessageEditor
                v-model="message"
                class="message-editor"
                :class="{ editor_warning: v$.message.$error }"
                :placeholder="$t('CAMPAIGN.ADD.FORM.MESSAGE.PLACEHOLDER')"
                @blur="v$.message.$touch"
              />
              <span v-if="v$.message.$error" class="editor-warning__message">
                {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.ERROR') }}
              </span>
            </div>
          </div>

          <label v-else :class="{ error: v$.message.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.LABEL') }}
            <textarea
              v-model="message"
              rows="5"
              type="text"
              :placeholder="$t('CAMPAIGN.ADD.FORM.MESSAGE.PLACEHOLDER')"
              @blur="v$.message.$touch"
            />
            <span v-if="v$.message.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.ERROR') }}
            </span>
          </label>
        </template>

        <label
          v-if="isOneOffType"
          class="multiselect-wrap--small"
          :class="{ error: v$.selectedAudience.$error }"
        >
          {{ $t('CAMPAIGN.ADD.FORM.AUDIENCE.LABEL') }}
          <multiselect
            v-model="selectedAudience"
            :options="audienceList"
            track-by="id"
            label="title"
            multiple
            :close-on-select="false"
            :clear-on-select="false"
            hide-selected
            :placeholder="$t('CAMPAIGN.ADD.FORM.AUDIENCE.PLACEHOLDER')"
            selected-label
            :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
            :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
            @blur="v$.selectedAudience.$touch"
            @select="v$.selectedAudience.$touch"
          />
          <span v-if="v$.selectedAudience.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.AUDIENCE.ERROR') }}
          </span>
        </label>

        <label
          v-if="isOngoingType || isEnabledSelectedSender"
          :class="{ error: v$.selectedSender.$error }"
        >
          {{ $t('CAMPAIGN.ADD.FORM.SENT_BY.LABEL') }}
          <select v-model="selectedSender">
            <option
              v-for="sender in sendersAndBotList"
              :key="sender.name"
              :value="sender.id"
            >
              {{ sender.name }}
            </option>
          </select>
          <span v-if="v$.selectedSender.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.SENT_BY.ERROR') }}
          </span>
        </label>

        <label v-if="isOneOffType"  :class="{ error: v$.scheduledAt.$error }">
          {{ $t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.LABEL') }}
          <WootDateTimePicker
            :value="scheduledAt"
            :confirm-text="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.CONFIRM')"
            :placeholder="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.PLACEHOLDER')"
            @change="onChange"
          />
          <span v-if="v$.scheduledAt.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.ERROR') }}
          </span>
        </label>

        <woot-input
          v-if="isOngoingType"
          v-model="endPoint"
          :label="$t('CAMPAIGN.ADD.FORM.END_POINT.LABEL')"
          type="text"
          :class="{ error: v$.endPoint.$error }"
          :error="
            v$.endPoint.$error ? $t('CAMPAIGN.ADD.FORM.END_POINT.ERROR') : ''
          "
          :placeholder="$t('CAMPAIGN.ADD.FORM.END_POINT.PLACEHOLDER')"
          @blur="v$.endPoint.$touch"
        />
        <woot-input
          v-if="isOngoingType"
          v-model="timeOnPage"
          :label="$t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.LABEL')"
          type="text"
          :class="{ error: v$.timeOnPage.$error }"
          :error="
            v$.timeOnPage.$error
              ? $t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.ERROR')
              : ''
          "
          :placeholder="$t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.PLACEHOLDER')"
          @blur="v$.timeOnPage.$touch"
        />
        <label v-if="isOngoingType">
          <input
            v-model="enabled"
            type="checkbox"
            value="enabled"
            name="enabled"
          />
          {{ $t('CAMPAIGN.ADD.FORM.ENABLED') }}
        </label>
        <label v-if="isOngoingType">
          <input
            v-model="triggerOnlyDuringBusinessHours"
            type="checkbox"
            value="triggerOnlyDuringBusinessHours"
            name="triggerOnlyDuringBusinessHours"
          />
          {{ $t('CAMPAIGN.ADD.FORM.TRIGGER_ONLY_BUSINESS_HOURS') }}
        </label>
      </div>

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <woot-button :is-loading="uiFlags.isCreating">
          {{ $t('CAMPAIGN.ADD.CREATE_BUTTON_TEXT') }}
        </woot-button>
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
::v-deep .ProseMirror-woot-style {
  height: 5rem;
}

.message-editor {
  @apply px-3;

  ::v-deep {
    .ProseMirror-menubar {
      @apply rounded-tl-[4px];
    }
  }
}
</style>
