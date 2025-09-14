<script>
const SCRIPT_NAME = 'snapshot-script';

export default {
  name: 'AgentTest',

  data() {
    return {
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      userPrompt: '',
      isRunning: false,
      scriptContent: '',
      website: null,
      injectError: null,
      isUpdatingAgent: false,
    };
  },

  computed: {
    botId() {
      return this.$route?.query?.agent || null;
    },
    agentBot() {
      return this.$store.getters['agentBots/getBot']?.(this.botId) || null;
    },
    canStart() {
      return !!this.agentBot && !this.isRunning;
    },
  },

  async mounted() {
    try {
      if (this.botId) {
        await this.$store.dispatch('agentBots/show', this.botId);
      }
      this.userPrompt = this.agentBot?.prompt || '';
    } catch (e) {
      console.log('agentBots/show error:', e);
    }
  },

  watch: {
    botId: {
      immediate: false,
      async handler(newId) {
        if (!newId) return;
        try {
          await this.$store.dispatch('agentBots/show', newId);
          this.userPrompt = this.agentBot?.prompt || '';
        } catch (e) {
          console.error('agentBots/show (watch) error:', e);
        }
      },
    },
  },
  beforeRouteLeave(to, from, next) {
    try {
      this.removeScript();
    } catch (e) {
      console.log('removeScript error:', e);
    }
    try {
      this.deleteInbox();
    } catch (e) {
      console.log('deleteInbox error:', e);
    }
    next();
  },
  beforeRouteUpdate() {
    try {
      this.removeScript();
    } catch (e) {
      console.error('removeScript error:', e);
    }
    try {
      this.deleteInbox();
    } catch (e) {
      console.error('deleteInbox error:', e);
    }
  },
  beforeDestroy() {
    try {
      console.log('removeScript beforeDestroy');
      this.removeScript();
    } catch (e) {
      console.error('removeScript error:', e);
    }
    try {
      console.log('deleteInbox');
      this.deleteInbox();
    } catch (e) {
      console.error('deleteInbox error:', e);
    }
  },
  methods: {
    async onStart() {
      if (!this.canStart) return;

      this.isRunning = true;
      this.injectError = null;

      try {
        if (this.website?.id) {
          await this.deleteInbox();
          this.website = null;
        }

        const website = await this.$store.dispatch(
          'inboxes/createWebsiteChannel',
          {
            name: 'snapshot',
            greeting_enabled: false,
            greeting_message: 'Hi there!',
            channel: {
              type: 'web_widget',
              website_url: null,
              widget_color: null,
              welcome_title: 'Snapshot!',
              welcome_tagline: 'Bienvenido al entorno de prueba de Snapshot',
            },
          }
        );

        this.website = website || null;
        this.scriptContent = website?.web_widget_script || '';

        if (this.website?.id && this.agentBot?.id) {
          await this.$store.dispatch('agentBots/setAgentBotInbox', {
            inboxId: this.website.id,
            botId: this.agentBot.id,
          });
        }

        this.injectWidgetScript(this.scriptContent);
      } catch (e) {
        console.error('onStart error:', e);
        this.injectError = e?.message || 'Unexpected error';
      } finally {
        this.isRunning = false;
      }
    },

    async updateAgent() {
      if (!this.agentBot?.id) return;

      this.isUpdatingAgent = true;
      try {
        await this.$store.dispatch('agentBots/update', {
          id: this.agentBot.id,
          name: this.agentBot.name,
          description: this.agentBot.description,
          prompt: this.userPrompt,
          init_at: this.agentBot.initAt,
          finish_at: this.agentBot.finishAt,
        });
      } catch (e) {
        console.log('updateAgent error:', e);
      } finally {
        this.isUpdatingAgent = false;
      }
    },

    reset() {
      this.isRunning = false;
      this.injectError = null;
    },
    onRemove() {
      try {
        console.log('removeScript beforeDestroy');
        this.removeScript();
      } catch (e) {
        console.error('removeScript error:', e);
      }
      try {
        console.log('deleteInbox');
        this.deleteInbox();
      } catch (e) {
        console.error('deleteInbox error:', e);
      }
    },
    removeScript() {
      const scripts = document.getElementsByName(SCRIPT_NAME);
      Array.from(scripts).forEach(el => el.remove());
    },
    injectWidgetScript(rawScript) {
      this.onRemove();

      if (!rawScript) return;
      const decoded = rawScript
        .replace(/\\u003c/g, '<')
        .replace(/\\u003e/g, '>');
      const match = decoded.match(/<script[^>]*>([\s\S]*?)<\/script>/i);
      const code = match ? match[1] : decoded;

      const blob = new Blob([code], { type: 'text/javascript' });
      const src = URL.createObjectURL(blob);

      const script = document.createElement('script');
      script.name = SCRIPT_NAME;
      script.type = 'text/javascript';
      script.src = src;
      script.async = true;

      script.onload = () => URL.revokeObjectURL(src);
      script.onerror = () => {
        URL.revokeObjectURL(src);
        console.error('Failed to load injected script');
      };

      document.head.appendChild(script);
    },
    async deleteInbox() {
      if (!this.website?.id) return;
      try {
        await this.$store.dispatch('inboxes/delete', this.website.id);
      } catch (e) {
        console.log('deleteInbox error:', e);
      }
    },
  },
};
</script>

<template>
  <div class="p-3">
    <div
      class="grid gap-4 min-h-[520px] grid-cols-1 md:grid-cols-2 lg:grid-cols-[65%_35%]"
    >
      <section class="bg-white dark:bg-slate-800 rounded-2xl p-4 shadow-sm">
        <header class="flex flex-col gap-1 mb-4">
          <h2 class="text-xl font-bold">
            {{ $t('AGENTS_AI.MODALS.SNAPSHOT.TITLE') }}
          </h2>
          <p class="text-slate-500 text-sm">
            {{ $t('AGENTS_AI.MODALS.SNAPSHOT.SUBTITLE') }}
          </p>
        </header>

        <div class="flex items-center gap-3 mb-2">
          <img
            :src="avatarDefault"
            alt="logo"
            class="w-16 h-16 rounded object-cover"
          />
          <h3 class="text-lg font-semibold" v-if="agentBot">
            {{ agentBot.name }}
          </h3>
          <span v-else class="text-sm text-slate-500">
            {{ $t('AGENTS_AI.MODALS.SNAPSHOT.LOADING_AGENT') }}
          </span>
        </div>

        <label for="userPrompt" class="block font-semibold mb-2">
          {{ $t('AGENTS_AI.MODALS.SNAPSHOT.USER_PROMPT_LABEL') }}
        </label>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-3">
          <div class="md:col-span-2">
            <textarea
              id="userPrompt"
              v-model.trim="userPrompt"
              :placeholder="
                $t('AGENTS_AI.MODALS.SNAPSHOT.USER_PROMPT_PLACEHOLDER')
              "
              maxlength="1000"
              :aria-describedby="'userPromptHint userPromptCount'"
              class="w-full h-full resize-y rounded-xl border border-slate-200 px-3 py-2 outline-none transition-shadow focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2 bg-white text-slate-900 dark:bg-slate-900 dark:text-slate-100 dark:border-slate-700 dark:focus:ring-offset-slate-900"
            ></textarea>
            <div class="mt-1 text-xs text-slate-500" id="userPromptCount">
              {{ (userPrompt || '').length }}/1000
            </div>
          </div>

          <aside class="space-y-2">
            <div
              class="bg-slate-50 border border-slate-200 rounded-xl p-4 dark:bg-slate-800 dark:border-slate-700"
            >
              <h3 class="text-sm font-bold mb-2">
                {{ $t('AGENTS_AI.MODALS.SNAPSHOT.INSTRUCTIONS_TITLE') }}
              </h3>
              <ul
                class="list-disc pl-5 text-slate-700 dark:text-slate-200 space-y-1 text-sm leading-relaxed"
              >
                <li>{{ $t('AGENTS_AI.MODALS.SNAPSHOT.BULLET_CONFIGURE') }}</li>
                <li>{{ $t('AGENTS_AI.MODALS.SNAPSHOT.BULLET_TRY') }}</li>
                <li>{{ $t('AGENTS_AI.MODALS.SNAPSHOT.BULLET_MONITOR') }}</li>
                <li>{{ $t('AGENTS_AI.MODALS.SNAPSHOT.BULLET_TUNE') }}</li>
              </ul>
              <p v-if="injectError" class="mt-2 text-xs text-red-600">
                {{ injectError }}
              </p>
            </div>

            <woot-button
              color-scheme="success"
              class="w-full mt-2 text-center"
              size="expanded"
              is-expanded
              :disabled="!canStart"
              @click="onStart"
            >
              <template v-if="isRunning">
                {{ $t('COMMON.LOADING') }}…
              </template>
              <template v-else>
                {{ $t('AGENTS_AI.MODALS.SNAPSHOT.BUTTON_START') }}
              </template>
            </woot-button>

            <woot-button
              color-scheme="primary"
              class="w-full mt-2 text-center"
              size="expanded"
              is-expanded
              :disabled="!agentBot || isUpdatingAgent"
              @click="updateAgent"
            >
              <template v-if="isUpdatingAgent">
                {{ $t('COMMON.SAVING') }}…
              </template>
              <template v-else>
                {{ $t('AGENTS_AI.MODALS.SNAPSHOT.BUTTON_SET_CONFIG') }}
              </template>
            </woot-button>
          </aside>
        </div>
      </section>
    </div>
  </div>
</template>
