<script>
import { mapGetters } from 'vuex';
import AgentBotsAPI from '../../../../api/agentBots';

export default {
  name: 'TemplatesAgentsIA',
  data() {
    const base = process.env.AGENTIC_EASY_CONTACT || '';
    return {
      exceededLimit: true,
      showAlertLimit: false,
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      templates: [
        {
          id: 'receptionist',
          nameKey: 'RECEPTIONIST',
          descriptionKey: 'RECEPTIONIST_DESC',
          icon: '🎧',
          prompt: `# ROL Y ESTILO
- Eres un recepcionista virtual amable y servicial.
- Saluda a los contactos, identifica sus necesidades y captura los detalles esenciales.
- Dirige las conversaciones al equipo o persona adecuada para obtener ayuda adicional.
- Habla con claridad y mantén la calma.

# INSTRUCCIONES
- Formula solo una pregunta a la vez.
- Si la consulta requiere un equipo específico, recopila la información necesaria antes de derivar.`,
          agent_type: 0,
          outgoing_url: `${base}/api/agent/maria`,
        },
        {
          id: 'sales',
          nameKey: 'SALES_AGENT',
          descriptionKey: 'SALES_AGENT_DESC',
          icon: '💰',
          prompt: `# ROL Y ESTILO
- Eres un agente de ventas virtual atento y profesional.
- Saluda a los clientes potenciales, conoce sus necesidades y sugiere productos adecuados.
- Conecta con el equipo correspondiente cuando el cliente esté listo.
- Sé amable y orientado a ayudar sin presionar.

# INSTRUCCIONES
- Formula una pregunta a la vez.
- Escucha las necesidades antes de sugerir.`,
          agent_type: 1,
          outgoing_url: `${base}/api/agent/sales`,
        },
        {
          id: 'support',
          nameKey: 'SUPPORT_AGENT',
          descriptionKey: 'SUPPORT_AGENT_DESC',
          icon: '💜',
          prompt: `# ROL Y ESTILO
- Eres un agente de soporte que responde preguntas sobre productos usando las fuentes de conocimiento.
- Cuando sea necesario, deriva el caso a un humano sin problemas.
- Sé claro, paciente y orientado a resolver.

# INSTRUCCIONES
- Usa la información de las fuentes de conocimiento para responder.
- Si no puedes resolver, deriva amablemente a un agente humano.`,
          agent_type: 0,
          outgoing_url: `${base}/api/agent/maria`,
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  async mounted() {
    await this.verifyLimitAgentBot();
  },
  methods: {
    async verifyLimitAgentBot() {
      try {
        await AgentBotsAPI.limit_status();
        this.exceededLimit = false;
      } catch (error) {
        this.exceededLimit = true;
      }
    },
    goBack() {
      this.$router.push({ name: 'settings_agents_ia' });
    },
    async useTemplate(t) {
      await this.verifyLimitAgentBot();
      if (this.exceededLimit) {
        this.showAlertLimit = true;
        return;
      }
      this.$router.push({
        name: 'settings_agents_ia_create',
        query: { template: t.id },
      });
    },
    async startFromScratch() {
      await this.verifyLimitAgentBot();
      if (this.exceededLimit) {
        this.showAlertLimit = true;
        return;
      }
      this.$router.push({
        name: 'settings_agents_ia_create',
        query: { from: 'scratch' },
      });
    },
  },
};
</script>

<template>
  <div class="flex-1 min-w-0 p-8 overflow-auto bg-slate-50 dark:bg-slate-900">
    <!-- Header -->
    <div class="mb-6 px-4">
      <button
        @click="goBack"
        class="inline-flex items-center gap-2 text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white mb-4"
      >
        <fluent-icon icon="arrow-left" size="20" />
        <span>{{ $t('AGENTS_AI.TEMPLATES.TITLE') }}</span>
      </button>
      <p class="text-sm text-slate-600 dark:text-slate-400">
        {{ $t('AGENTS_AI.TEMPLATES.DESCRIPTION') }}
      </p>
    </div>

    <!-- Grid: 3 templates + crear desde cero -->
    <div class="px-4 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl">
      <!-- Template cards -->
      <div
        v-for="t in templates"
        :key="t.id"
        class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-6 flex flex-col"
      >
        <div class="flex justify-center items-center h-14 mb-4 text-4xl">
          {{ t.icon }}
        </div>
        <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-2">
          {{ $t('AGENTS_AI.TEMPLATES.ITEMS.' + t.nameKey) }}
        </h3>
        <p class="text-sm text-slate-600 dark:text-slate-400 flex-1 mb-4">
          {{ $t('AGENTS_AI.TEMPLATES.ITEMS.' + t.descriptionKey) }}
        </p>
        <woot-button
          variant="smooth"
          color-scheme="secondary"
          size="small"
          class="w-full"
          :disabled="exceededLimit"
          @click="useTemplate(t)"
        >
          {{ $t('AGENTS_AI.TEMPLATES.USE_TEMPLATE') }}
        </woot-button>
      </div>

      <!-- Crear desde cero -->
      <div
        class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 border-dashed p-6 flex flex-col items-center justify-center"
      >
        <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1">
          {{ $t('AGENTS_AI.TEMPLATES.CREATE_FROM_SCRATCH.TITLE') }}
        </h3>
        <p class="text-sm text-slate-600 dark:text-slate-400 mb-4 text-center">
          {{ $t('AGENTS_AI.TEMPLATES.CREATE_FROM_SCRATCH.SUBTITLE') }}
        </p>
        <woot-button
          color-scheme="primary"
          icon="add"
          :disabled="exceededLimit"
          @click="startFromScratch"
        >
          {{ $t('AGENTS_AI.TEMPLATES.CREATE_FROM_SCRATCH.BUTTON') }}
        </woot-button>
      </div>
    </div>

    <!-- Alert limit (reuse existing or simple div) -->
    <div v-if="showAlertLimit" class="fixed inset-0 bg-black/30 flex items-center justify-center z-50 p-4">
      <div class="bg-white dark:bg-slate-800 rounded-lg shadow-xl p-6 max-w-md">
        <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-2">{{ $t('AGENTS_AI.PAYMENT.TITLE') }}</h3>
        <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
          {{ $t('AGENTS_AI.PAYMENT.MESSAGE') }}
          <a target="_blank" :href="$t('AGENTS_AI.PAYMENT.REFERENCE.REDIRECT')" class="text-woot-500">
            {{ $t('AGENTS_AI.PAYMENT.REFERENCE.TITLE') }}
          </a>
        </p>
        <woot-button color-scheme="primary" @click="showAlertLimit = false">
          {{ $t('AGENTS_AI.TEMPLATES.ALERT_CLOSE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
