<script>
import { mapGetters } from 'vuex';
import ModalAgentRag from './components/agentRag/ModalAgentRag.vue';
import ModalAgentCalendar from './components/ModalAgentCalendar.vue';
import ModalAgentConfigutarion from './components/ModalAgentConfiguration.vue';
import ModalAgentCatalog from './components/agentCatalog/ModalAgentCatalog.vue';

export default {
  components: {
    ModalAgentRag,
    ModalAgentCalendar,
    ModalAgentCatalog,
    ModalAgentConfigutarion
  },
  data() {
    return {
      showAgentRag: false,
      showAgentCalendar: false,
      showAgentCatalog: false,
      showAgentConfiguration: false,
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
    }
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      uiFlags: 'agentBots/getUIFlags',
    }),
    agentBot() {
      const botId = this.$route.query.agent;
      return this.$store.getters['agentBots/getBot'](botId);
    },

    cards() {
      return [
        {
          id: 1,
          inDeploy: false,
          action: () => { this.showAgentRag = true },
          name: this.$t('AGENTS_AI.CARDS.RAG.NAME'),
          image: '/assets/images/dashboard/agents-ai/rag.webp'
        },
        {
          id: 2,
          inDeploy: false,
          action: () => { this.showAgentCalendar = true },
          name: this.$t('AGENTS_AI.CARDS.CALENDAR.NAME'),
          image: '/assets/images/dashboard/agents-ai/calendar.png'
        },
        {
          id: 3,
          inDeploy: false,
          action: () => { this.showAgentCatalog = true },
          name: this.$t('AGENTS_AI.CARDS.CATALOG.NAME'),
          image: '/assets/images/dashboard/agents-ai/catalog.png'
        },
        {
          id: 4,
          inDeploy: false,
          action: () => { this.showAgentConfiguration = true },
          name: this.$t('AGENTS_AI.CARDS.CONFIGURATION.NAME'),
          image: '/assets/images/dashboard/agents-ai/agent-settings.png'
        },
        {
          id: 5,
          inDeploy: false,
          action: () => {
            this.$router.push({
              name: 'settings_agent_test',
              query: { agent: this.agentBot?.id },
            });
          },
          name: this.$t('AGENTS_AI.CARDS.SANDBOX.NAME'),
          image: '/assets/images/dashboard/agents-ai/agent-test.png'
        }
      ];
    }
  },
  mounted() {
    this.$store.dispatch('agentBots/get');
  },
  methods: {
    hideAgentRag() { this.showAgentRag = false },
    hideAgentCalendar() { this.showAgentCalendar = false },
    hideAgentCatalog() { this.showAgentCatalog = false },
    hideAgentConfiguration() { this.showAgentConfiguration = false },
    getAgentBot() {
      console.log(this.agentBot)
    }
  }
}
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-4 overflow-auto">

    <!-- MODALS  -->
    <woot-modal :show.sync="this.showAgentRag" :on-close="hideAgentRag">
      <ModalAgentRag :on-close="hideAgentRag" :botId="agentBot.id" :accountId="agentBot.account_id" />
    </woot-modal>

    <woot-modal :show.sync="this.showAgentCalendar" :on-close="hideAgentCalendar">
      <ModalAgentCalendar :on-close="hideAgentCalendar" :botId="agentBot.id" :accountId="agentBot.account_id" />
    </woot-modal>

    <woot-modal :show.sync="this.showAgentCatalog" :on-close="hideAgentCatalog">
      <ModalAgentCatalog :on-close="hideAgentCatalog" :botId="agentBot.id" :accountId="agentBot.account_id" />
    </woot-modal>

    <woot-modal :show.sync="this.showAgentConfiguration" :on-close="hideAgentConfiguration">
      <ModalAgentConfigutarion :botId="agentBot.id" :botName="agentBot.name" :botAvatar="agentBot.avatar_url || avatarDefault" :botDescription="agentBot.description" :botPrompt="agentBot.prompt" :botInitAt="agentBot.init_at" :botFinishAt="agentBot.finish_at" :on-close="hideAgentConfiguration" />
    </woot-modal>
    <!-- MODALS  -->

    <!-- <button class="bg-green-300" @click="getAgentBot">BOT</button> -->


    <div class="px-4 text-base">
      <h1 class="font-bold ">{{ agentBot.name }}</h1>
      <p class="text-[12px]">{{ agentBot.description }}</p>
    </div>

    <div class="px-4">
      <p class="text-base line-clamp-5 sm:line-clamp-none max-w-3xl tracking-[-0.1px]">{{
        $t('AGENTS_AI.HEADER_CAPABILITIES.DESCRIPTION_A') }}</p>
      <p class="mb-2 text-base line-clamp-5 sm:line-clamp-none max-w-3xl tracking-[-0.1px]">{{
        $t('AGENTS_AI.HEADER_CAPABILITIES.DESCRIPTION_B') }}</p>

      <div class="grid max-w-3xl grid-cols-2 mx-0 mt-6 sm:grid-cols-3 lg:grid-cols-4">
        <button v-for="card in cards" :key="card.id" @click="card.action" :disabled="card.inDeploy"
          class="bg-white dark:bg-slate-900 cursor-pointer flex flex-col justify-end transition-all duration-200 ease-in py-4 px-2 items-center border border-solid border-slate-200 dark:border-slate-800 hover:border-woot-500 dark:hover:border-woot-500 hover:shadow-md">
          <div class="w-full h-32 p-2 flex justify-center items-center">
            <img :src="card.image" :alt="card.name" class="h-full object-cover" />
          </div>
          <p class="mt-2 text-center text-sm font-medium text-slate-700 dark:text-slate-100">
            {{ card.name }}
          </p>
          <p v-if="card.inDeploy" class="bg-amber-500 text-black rounded-full px-2 text-xs">{{
            $t('AGENTS_AI.CARDS.IN_DEPLOY') }}</p>
        </button>
      </div>
    </div>
  </div>
</template>
