<script>
import Spinner from 'shared/components/Spinner.vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import WootSubmitButton from '../../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../../components/Modal.vue';
import TinyEditor from '../widgets/TinyEditor.vue';

export default {
  name: "ModalAgentAdd",
  components: { Modal, WootSubmitButton, Spinner, TinyEditor },
  props: {
    onClose: {
      type: Function,
      default: () => { },
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
    isCreating() {
      return this.uiFlags.isCreating;
    }
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      agentName: '',
      agentDescription: '',
      agentType:0,
      agentPrompt: '',
      scheduleEnabled: false,
      initAt: '',
      finishAt: '',
      show: true,
      agentTypes: [
        { value: 0, option: this.$t('AGENTS_AI.ADD.FORM.SELECT.0'), url:`${process.env.AGENTIC_EASY_CONTACT}/api/agent/maria` },
        { value: 1, option: this.$t('AGENTS_AI.ADD.FORM.SELECT.1'), url:`${process.env.AGENTIC_EASY_CONTACT}/api/agent/sales` }
      ],
      file:'',
      image:'/assets/images/dashboard/agents-ai/robot.png'
    };
  },
  validations: {
    agentName: {
      required
    },
    agentDescription: {
      default: ''
    },
    agentType: {
      required
    },
    agentPrompt: {
      required
    },
    initAt: {
      default: ''
    },
    finishAt: {
      default: ''
    },
  },
  methods: {
    toggleScheduleEnabled() {
      if (!this.scheduleEnabled === false) {
        this.initAt = '';
        this.finishAt = '';
      }
      this.scheduleEnabled = !this.scheduleEnabled;
    },
    onChangeAvatar(event) {
      try {
        this.file = event.target.files[0]
        if (!this.file) return
        const reader = new FileReader();
        reader.onload = e => {
          this.image = e.target.result;
        };
        reader.readAsDataURL(this.file);
      } catch (error) {
        console.warn({ error })
      }
    },
    async createAgentBot() {
      const formData = new FormData()
      const data = {
        name: this.agentName,
        description: this.agentDescription,
        prompt: this.agentPrompt,
        agent_type: this.agentType,
        outgoing_url: this.agentTypes[this.agentType].url,
        init_at: this.initAt,
        finish_at: this.finishAt
      }
      if (this.file)
        data.avatar = this.file
      for (const [key, value] of Object.entries(data)) {
        if (value !== undefined && value !== null && value !== '')
          formData.append(key, value)
      }
      try {
        await this.$store.dispatch('agentBots/create', formData)
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.CREATE.SUCCESS'))
        this.onClose()
      } catch (error) {
        if (error?.response?.status == 402) {
          useAlert(this.$t('AGENTS_AI.PAYMENT_REQUIRED'))
          return
        }
        useAlert(this.$t('AGENTS_AI.ALERT.AGENT_BOT.CREATE.ERROR'))
      }
    }
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('AGENTS_AI.ADD.NAME')" :header-content="$t('AGENTS_AI.ADD.DESCRIPTION')" />

      <form class="flex flex-col w-full" @submit.prevent="createAgentBot">
        <div class="flex w-full gap-5">
          <div class="flex-1">
            <woot-input v-model="agentName" :label="$t('AGENTS_AI.ADD.FORM.NAME.LABEL')" type="text"
              :class="{ error: v$.agentName.$error }" :error="v$.agentName.$error
                ? $t('AGENTS_AI.ADD.FORM.NAME.ERROR')
                : ''
                " :placeholder="$t('AGENTS_AI.ADD.FORM.NAME.PLACEHOLDER')" @blur="v$.agentName.$touch" />

            <woot-input v-model="agentDescription" :label="$t('AGENTS_AI.ADD.FORM.DESCRIPTION.LABEL')" type="text"
              :class="{ error: v$.agentDescription.$error }" :error="v$.agentDescription.$error
                ? $t('AGENTS_AI.ADD.FORM.DESCRIPTION.ERROR')
                : ''
                " :placeholder="$t('AGENTS_AI.ADD.FORM.DESCRIPTION.PLACEHOLDER')" @blur="v$.agentDescription.$touch" />
          </div>
          <label for="avatar" :style="{ width: '26%', maxHeight: '165px', border:'1px dashed', padding:'10px' }" class="flex justify-center items-center rounded cursor-pointer">
            <img class="w-full" :src="image" alt="logo bot" />
            <input id="avatar" @change="onChangeAvatar" accept="image/*" type="file" class="hidden" />
          </label>
        </div>
        <div>
          <label for="agent-type">{{$t('AGENTS_AI.ADD.FORM.SELECT.LABEL')}}</label>
          <select v-model="agentType" id="agent-type" disabled class="disabled:cursor-not-allowed">
            <option v-for="agent in agentTypes" :key="agent.value" :value="agent.value">
              {{ agent.option }}
            </option>
          </select>
        </div>

        <span class="text-sm font-medium text-slate-900 dark:text-slate-100 mb-1">{{
          $t('AGENTS_AI.ADD.FORM.PROMPT.LABEL') }}</span>
        <TinyEditor v-model="agentPrompt" :height="250" />

        <div class="flex">
          <input class="me-2" id="scheduleEnabledId" v-model="scheduleEnabled" type="checkbox"
            @click="toggleScheduleEnabled" />
          <label for="scheduleEnabledId">{{ $t('AGENTS_AI.ADD.FORM.SCHEDULE.LABEL') }}</label>
        </div>

        <div v-if="scheduleEnabled" class="flex items-center justify-evenly w-full my-3">
          <woot-input v-model="initAt" :label="$t('AGENTS_AI.ADD.FORM.SCHEDULE.INIT')" type="time" />
          <woot-input v-model="finishAt" :label="$t('AGENTS_AI.ADD.FORM.SCHEDULE.FINISH')" type="time" />
        </div>

        <div class="flex flex-row justify-end items-center w-full gap-2 px-0 py-2">
          <WootSubmitButton :disabled="isButtonDisabled || isCreating" :button-text="$t('AGENTS_AI.ADD.FORM.SUBMIT')"
            :loading="isCreating" />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('AGENTS_AI.ADD.FORM.CANCEL') }}
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
