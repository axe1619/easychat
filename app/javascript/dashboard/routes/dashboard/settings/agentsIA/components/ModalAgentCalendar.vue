<script>
import Modal from '../../../../../components/Modal.vue';
import Spinner from 'shared/components/Spinner.vue';
import { mapGetters } from 'vuex';
import {frontUrl} from '../services/apiAgent'

export default {
  name: "ModalAngentCalendar",
  components: { Modal, Spinner },
  props: {
    onClose: {
      type: Function,
      default: () => { },
    },
    botId: {
      type: Number,
      default: 0
    },
    accountId: {
      type: Number,
      default: 0
    },
  },
  computed: {
    ...mapGetters({
      calendars: 'calendars/getCalendars',
      uiFlags: 'calendars/getUIFlags',
    }),
    agentCalendars() {
      return this.$store.getters['calendars/getCalendarsByAgentBotId'](Number(this.botId));
    },
    outSyncGoogleAccount() { //Verifica si la cuenta de google no esta sincronizada
      const calendars = this.$store.getters['calendars/getCalendarsByAgentBotId'](Number(this.botId))
      const result = calendars.some(i => i.platform === 'google')
      return !result
    },
    isFetching() {
      return this.uiFlags.isFetching;
    },
    isCreating() {
      return this.uiFlags.isCreating;
    },
    isDeleting() {
      return this.uiFlags.isDeleting;
    },
  },
  data() {
    return {
      show: true,
    }
  },
  mounted() {
    window.addEventListener('message', this.handleGoogleAuthMessage)
    this.$store.dispatch('calendars/get', { agent_bot_id: this.botId })
    window.addEventListener('message', this.handleGoogleAuthMessage)
    this.$store.dispatch('calendars/get', { agent_bot_id: this.botId })
  },
  beforeDestroy() {
    window.removeEventListener('message', this.handleGoogleAuthMessage)
  },
  methods: {
    loginWithGoogle() {
      window.open(
        `${frontUrl}/api/google`,
        'googleLoginPopup',
        'width=500,height=600'
      );
    },
    handleGoogleAuthMessage(event) {
      if (event.origin !== frontUrl) return

      const { access_token, refresh_token, id_token, user } = event.data
      console.log({ access_token, refresh_token, id_token, user })

      if (!access_token) {
        console.warn('Mensaje recibido sin access_token');
        return
      }

      const data = {
        platform: 'google',
        id_token: id_token,
        access_token: access_token,
        refresh_token: refresh_token,
        email: user.email,
        user_name: user.user_name,
        picture: user.picture,
      }

      if (this.isCreating) return
      this.createCalendar(data)
    },
    async createCalendar(data) {
      const newData = {
        agent_bot_id: this.botId,
        account_id: this.accountId,
        ...data
      }
      await this.$store.dispatch('calendars/create', newData)
    },
    async deleteCalendar(id) {
      await this.$store.dispatch('calendars/delete', id)
    },
    getCalendars() {
      console.log('data', { agent_bot_id: this.botId, account_id: this.accountId, })
    }
  }

}
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto mb-8">
      <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.CALENDAR.NAME')"
        :header-content="$t('AGENTS_AI.CARDS.CALENDAR.DESCRIPTION')" />

      <!-- <button class="bg-green-300" @click="getCalendars">GET...</button> -->

      <div v-if="outSyncGoogleAccount" class="w-full flex justify-center mt-5">
        <woot-button class="button nice rounded-md" icon="add-circle" @click="loginWithGoogle"
          :disabled="isFetching || isCreating">
          {{ $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.ADD_GOOGLE_ACOUNT') }}
        </woot-button>
      </div>
      <!-- <div v-if="outSyncGoogleAccount"  class="w-full flex justify-center mt-5">
        <woot-button class="button nice rounded-md" icon="add-circle" @click="loginWithGoogle" :disabled="isFetching || isCreating">
          {{ $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.ADD_GOOGLE_ACOUNT') }}
        </woot-button>
      </div> -->

      <!-- <div v-if="isFetching" class="mt-5 flex justify-center items-center">
        <Spinner/>
      </div>
       -->
      <!-- <div v-if="agentCalendars" class="flex flex-col mx-8" >
        <div v-for="calendar in agentCalendars"
          class="flex justify-between items-center mt-5 p-3 rounded border border-solid border-slate-800 dark:border-slate-200">
          <div class="w-16 h-16 overflow-hidden rounded-full">
            <img :src="calendar.picture" class="object-cover">
          </div>
          <div class="text-center flex flex-col justify-center items-center" >
            <p class="text-base m-0 font-semibold">{{ calendar.user_name }}</p>
            <p class="text-sm m-0 font-medium">{{ calendar.email }}</p>
            <div v-if="calendar.platform === 'google'" class="dark:bg-slate-200 mt-2 px-2 rounded w-20 overflow-hidden">
              <img src="/assets/images/dashboard/agents-ai/google.png" alt="logo-google-calendar" class="object-cover">
            </div>
          </div>

          <div class="flex flex-col justify-center items-center" >
            <button class="bg-red-300 text-white" @click="deleteCalendar(calendar.id)">{{ $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.DELETE') }}</button>
          </div>
        </div>
      </div> -->

      <div v-if="isFetching" class="mt-5 flex justify-center items-center">
        <Spinner />
      </div>

      <div v-if="agentCalendars" class="flex flex-col mx-8">
        <div v-for="calendar in agentCalendars"
          class="flex justify-between items-center mt-5 p-3 rounded border border-solid border-slate-800 dark:border-slate-200">
          <div class="w-16 h-16 overflow-hidden rounded-full">
            <img :src="calendar.picture" class="object-cover">
          </div>
          <div class="text-center flex flex-col justify-center items-center">
            <p class="text-base m-0 font-semibold">{{ calendar.user_name }}</p>
            <p class="text-sm m-0 font-medium">{{ calendar.email }}</p>
            <div v-if="calendar.platform === 'google'" class="dark:bg-slate-200 mt-2 px-2 rounded w-20 overflow-hidden">
              <img src="/assets/images/dashboard/agents-ai/google.png" alt="logo-google-calendar" class="object-cover">
            </div>
          </div>

          <div class="flex flex-col justify-center items-center">
            <button class="bg-red-300 text-white" @click="deleteCalendar(calendar.id)">{{
              $t('AGENTS_AI.CARDS.CALENDAR.BUTTON.DELETE') }}</button>
          </div>
        </div>
      </div>
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
