<script>
import Spinner from 'shared/components/Spinner.vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import WootSubmitButton from '../../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../../components/Modal.vue';

export default {
  name: "ModalAgentConfigutarion",
  components: { Modal, WootSubmitButton, Spinner },
  props: {
    onClose: {
      type: Function,
      default: () => { },
    },
    botId: {
      type: Number,
      default: 0
    },
    botName: {
      type: String,
      default: ''
    },
    botDescription: {
      type: String,
      default: ''
    },
    botPrompt: {
      type: String,
      default: ''
    },
    botInitAt: {
      type: String,
      default: ''
    },
    botFinishAt: {
      type: String,
      default: ''
    }
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
    isButtonDisabled() {
      return (
        this.v$.agentName.$invalid ||
        this.v$.agentDescription.$invalid ||
        this.v$.agentPrompt.$invalid
      );
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },
    // isRegexEnabled() {
    //   return this.regexEnabled;
    // },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      agentId: this.botId,
      agentName: this.botName,
      agentDescription: this.botDescription,
      agentPrompt: this.botPrompt || '',
      scheduleEnabled: this.botInitAt !== '' || this.botFinishAt !== '',
      initAt: this.botInitAt,
      finishAt: this.botFinishAt,
      show: true,
    };
  },
  validations: {
    agentName: {
      required
    },
    agentDescription: {
      default:''
    },
    agentPrompt: {
      required
    },
    initAt: {
      default:''
    },
    finishAt: {
      default:''
    },
  },
  methods: {
    toggleScheduleEnabled() {
      if(!this.scheduleEnabled === false){
        this.initAt = '';
        this.finishAt = '';
      }
      this.scheduleEnabled = !this.scheduleEnabled;
    },
    async updateAgentBot() {
      const updateAgentBotData = {
        AgentId: this.agentId,
        AgentName: this.agentName,
        AgentDescription: this.agentDescription,
        AgentPrompt: this.agentPrompt,
        initAt: this.initAt,
        finishAt: this.finishAt,
        scheduleEnabled: this.scheduleEnabled,
      }
      console.log(updateAgentBotData)
      try {
        await this.$store.dispatch('agentBots/update', {
          id: this.agentId,
          name: this.agentName,
          description: this.agentDescription,
          prompt: this.agentPrompt,
          init_at: this.initAt,
          finish_at: this.finishAt,
        });
        useAlert(this.$t('AGENT_BOTS.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('AGENT_BOTS.CSML_BOT_EDITOR.BOT_CONFIG.API_ERROR'));
      }
    }
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.CONFIGURATION.NAME')"
        :header-content="$t('AGENTS_AI.CARDS.CONFIGURATION.DESCRIPTION')" />

      <form class="flex flex-col w-full" @submit.prevent="updateAgentBot">
        <woot-input v-model="agentName" :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.NAME.LABEL')" type="text"
          :class="{ error: v$.agentName.$error }" :error="v$.agentName.$error
            ? $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.NAME.ERROR')
            : ''
            " :placeholder="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.NAME.PLACEHOLDER')" @blur="v$.agentName.$touch" />

        <woot-input v-model="agentDescription" :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.LABEL')"
          type="text" :class="{ error: v$.agentDescription.$error }" :error="v$.agentDescription.$error
            ? $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.ERROR')
            : ''
            " :placeholder="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.DESCRIPTION.PLACEHOLDER')"
          @blur="v$.agentDescription.$touch" />

        <woot-text-area v-model.trim="agentPrompt" :class="{ error: v$.agentPrompt.$error }" class="w-full"
          :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.PROMPT.LABEL')"
          :placeholder="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.PROMPT.PLACEHOLDER')" data-testid="label-description"
          @input="v$.agentPrompt.$touch" :error="v$.agentPrompt.$error
            ? $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.PROMPT.ERROR')
            : ''
            " />

        <div class="flex">
          <input class="me-2" id="scheduleEnabledId" v-model="scheduleEnabled" type="checkbox" @click="toggleScheduleEnabled" />
          <label for="scheduleEnabledId">{{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.LABEL') }}</label>
        </div>

        <div v-if="scheduleEnabled" class="flex items-center justify-evenly w-full my-3">
          <woot-input v-model="initAt" :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.INIT')" type="time" />
          <woot-input v-model="finishAt" :label="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SCHEDULE.FINISH')" type="time" />
        </div>

        <div class="flex flex-row justify-end items-center w-full gap-2 px-0 py-2">
          <WootSubmitButton :disabled="isButtonDisabled || isUpdating"
            :button-text="$t('AGENTS_AI.CARDS.CONFIGURATION.FORM.SUBMIT')" :loading="isUpdating" />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('AGENTS_AI.CARDS.CONFIGURATION.FORM.CANCEL') }}
          </button>
        </div>
      </form>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    @apply hidden;
  }

  .ProseMirror-woot-style {
    @apply min-h-[12.5rem];

    p {
      @apply text-base;
    }
  }
}
</style>
