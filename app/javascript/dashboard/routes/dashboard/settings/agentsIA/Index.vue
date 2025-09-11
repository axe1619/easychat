<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import ModalAgentAdd from './components/ModalAgentAdd.vue';

export default {
  name: 'AgentsIa',
  components:{ Spinner, ModalAgentAdd },
  data() {
    return {
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      showAddAgent: false,
    }
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
    agentList() { return this.$store.getters['agentBots/getBots'] },
    isFetching() { return this.uiFlags.isFetching }
  },
  mounted() { this.$store.dispatch('agentBots/get') },
  methods: {
    openAddAgent() {
      this.showAddAgent = true
    },
    hideAddAgent() {
      this.showAddAgent = false
    },
  }
}
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-8 overflow-auto">
    <woot-button color-scheme="success" class-names="button--fixed-top" icon="add-circle" @click="openAddAgent()">
      {{ $t('AGENTS_AI.BUTTON.ADD') }}
    </woot-button>

    <!-- MODALS  -->
    <woot-modal :show.sync="showAddAgent" :on-close="hideAddAgent">
      <ModalAgentAdd :on-close="hideAddAgent" />
    </woot-modal>

    <p class="mb-4 text-base font-normal line-clamp-5 sm:line-clamp-none max-w-3xl tracking-[-0.1px]">{{
      $t('AGENTS_AI.HEADER_INDEX.DESCRIPTION') }}</p>

    <div class="flex">
      <div v-if="isFetching" class="w-full flex justify-center items-center m-4">
        <Spinner />
      </div>
      <div v-for="a in agentList" :key="a.id"
        class="w-60 m-2 bg-white dark:bg-slate-900 cursor-pointer flex flex-col justify-end transition-all duration-200 ease-in px-0 items-center border border-solid border-slate-25 dark:border-slate-800 hover:border-woot-500 dark:hover:border-woot-500 hover:shadow-md rounded">
        <router-link :to="'capabilities?agent=' + a.id" class="w-full h-full p-3 flex flex-col justify-between">
          <div class="w-full h-32 p-2 flex justify-center items-center">
            <img :src="a.avatar_url || avatarDefault" :alt="a.name" class="h-full object-cover" />
          </div>
          <h1
            class="text-center font-bold text-slate-700 dark:text-slate-100 border border-solid border-slate-25 dark:border-slate-800 rounded ">
            {{ a.name }}
          </h1>
          <p class="px-2 mb-0 mt-1 leading-normal text-center text-[12px] text-slate-700 dark:text-slate-100">
            {{ a.description }}</p>
        </router-link>
      </div>
    </div>
  </div>
</template>
