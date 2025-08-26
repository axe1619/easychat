<script>
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import SwitchButton from "dashboard/components/ui/Switch.vue";
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, numeric, minValue, maxValue, minLength } from '@vuelidate/validators';

const UNIT_TIME = {
  MINUTES: 0,
  HOURS: 1
}

export default {
  components: {
    SettingsSection,
    SwitchButton
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      behaviorRemarketing: "",
      enabledRemarketing: null,
      coutMaxRemarketingMessage: 1,
      timeWaitLastMessage: 1,
      unitTime: UNIT_TIME.MINUTES,
    };
  },
  setup() {
    return { v$: useVuelidate() };
  },
  validations() {
    return {
      behaviorRemarketing: {
        required,
        minLength: minLength(10),
      },
      coutMaxRemarketingMessage: {
        required,
        minValue: minValue(1),
        maxValue: maxValue(20),
        numeric
      },
      timeWaitLastMessage: this.validateTimeWaitLastMessage(this.unitTime)
    }
  },
  computed: {
    messageErrorBehaviorRemarketing() {
      const field = this.v$.behaviorRemarketing
      if (field.required.$invalid)
        return this.$t("INBOX_MGMT.REMARKETING.BEHAVIOR.REQUIRED");
      if (field.minLength.$invalid)
        return this.$t("INBOX_MGMT.REMARKETING.BEHAVIOR.LENGTH");
    },
    messageErrorCoutMaxRemarketingMessage() {
      const field = this.v$.coutMaxRemarketingMessage
      if (field.required.$invalid)
        return this.$t("INBOX_MGMT.REMARKETING.COUNT_MAX_REMARKETING_MESSAGE.REQUIRED");
      if (field.minValue.$invalid || field.maxValue.$invalid)
        return this.$t("INBOX_MGMT.REMARKETING.COUNT_MAX_REMARKETING_MESSAGE.SIZE");
    },
    messageErrorTimeWaitLastMessage() {
      const field = this.v$.timeWaitLastMessage
      if (field.minValue.$invalid && this.unitTime == UNIT_TIME.MINUTES)
        return this.$t("INBOX_MGMT.REMARKETING.TIME_WAIT_LAST_MESSAGE.MIN_MINUTES");
      if (field.minValue.$invalid && this.unitTime == UNIT_TIME.HOURS)
        return this.$t("INBOX_MGMT.REMARKETING.TIME_WAIT_LAST_MESSAGE.MIN_HOURS");      
    }
  },
  methods: {
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          behavior_remarketing: this.behaviorRemarketing,
          enabled_remarketing: this.enabledRemarketing,
          cout_max_remarketing_message: this.coutMaxRemarketingMessage,
          time_wait_last_message: this.timeWaitLastMessage,
          unit_time: this.unitTime
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    onSwitchRemarketing(value) {
      this.enabledRemarketing = value
      try {
      } catch (error) {
        this.enabledRemarketing = !value
      }
    },
    onUpdateConfigMessageRemarketing() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.updateInbox()
    },
    validateTimeWaitLastMessage(time) {
      if (time == UNIT_TIME.MINUTES) {
        return {
          minValue: minValue(5),
          numeric
        }
      }
      return {
        minValue: minValue(1),
        numeric
      }
    },
    loadDataRemarketing() {
      this.behaviorRemarketing = this.inbox.behavior_remarketing ?? "";
      this.enabledRemarketing = this.inbox.enabled_remarketing;
      this.coutMaxRemarketingMessage = this.inbox.cout_max_remarketing_message;
      this.timeWaitLastMessage = this.inbox.time_wait_last_message;
      this.unitTime = this.inbox.unit_time;
    }
  },
  mounted() {
    this.loadDataRemarketing()
  }
};
</script>

<template>
  <div class="mx-8">
    <SettingsSection title='Envio de mensajes automaticos'
      sub-title='Envíe mensajes automáticos a sus clientes en intervalos programados para dar seguimiento a las conversaciones y mantener una comunicación constante.'>
      <div class="w-4/5">
        <div>
          <template v-if="enabledRemarketing == null" class="flex justify-between items-center">
            <span class="spinner" />
          </template>
          <template v-else>
            <div class="flex justify-between items-center">
              <label class="mb-2">Habilitar remarketing</label>
              <SwitchButton :value="enabledRemarketing" @input="onSwitchRemarketing" />
            </div>
          </template>
        </div>
        <div>
          <woot-text-area 
            v-model.trim="behaviorRemarketing" 
            class="w-full mb-0" 
            label="Instrucciones del mensaje"
            placeholder="Comportamiento del agente ia..." 
            :class="{ error: v$.behaviorRemarketing.$error }"
          />
          <small v-if="v$.behaviorRemarketing.$error" class="message error">
            {{ messageErrorBehaviorRemarketing }}
          </small>
          <woot-input 
            v-model.trim="coutMaxRemarketingMessage"
            type="number" 
            label="Cantidad maxima de mensajes"
            class="mb-0"
            :class="{ error: v$.coutMaxRemarketingMessage.$error }"
          />
          <small v-if="v$.coutMaxRemarketingMessage.$error " class="message error">
            {{ messageErrorCoutMaxRemarketingMessage }}
          </small>
          <div>
            <label>Tiempo de espera despues del ultimo mensaje</label>
            <div class="flex gap-2">
              <woot-input 
                v-model.trim="timeWaitLastMessage" 
                type="number" 
                class="w-[70%] mb-0"
                :class="{ error: v$.timeWaitLastMessage.$error }"
              />
              <select v-model="unitTime" class="w-[30%] mb-0">
                <option value="0">Minute</option>
                <option value="1">Hora</option>
              </select>
            </div>
            <small v-if="v$.timeWaitLastMessage.$error" class="message">
              {{ messageErrorTimeWaitLastMessage }}
            </small>
          </div>
        </div>
        <div class="mt-2">
          <woot-button type="button" @click="onUpdateConfigMessageRemarketing">
            Actualizar
          </woot-button>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
