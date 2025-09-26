<script>
import { act } from 'react';
import agentBots from '../../../../../store/modules/agentBots';
import TinyEditor from '../widgets/TinyEditor.vue';

const SCRIPT_NAME = 'snap-script';

export default {
  name: 'AgentTest',
  components: { TinyEditor },

  data() {
    return {
      avatarDefault: '/assets/images/dashboard/agents-ai/robot.png',
      userPrompt: '',
      agentId: '',
      originalPrompt: '',
      isRunning: false,
      scriptContent: '',
      website: null,
      injectError: null,
      isUpdatingAgent: false,
      editorKey: 0,
      hasStarted: false,
      cleanUp: false,
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
      return (
        !!this.agentBot &&
        !!this.normalizeContent(this.userPrompt) &&
        !this.isRunning
      );
    },
    isDirty() {
      return (
        this.normalizeContent(this.userPrompt) !==
        this.normalizeContent(this.originalPrompt)
      );
    },
  },

  async mounted() {
    try {
      if (this.botId) {
        await this.$store.dispatch('agentBots/show', this.botId);
        // console.log('on remove 1');
        // this.onRemove();
        await this.$nextTick();
        // await this.onStart(
        //   this.$store.getters['agentBots/getBot']?.(this.botId)?.id
        // );
      }
    } catch (e) {
      console.log('agentBots/show error:', e);
    }

    this._beforeUnload = () => {
      try {
        console.log('on remove 10');
        this.onRemove();
      } catch (e) {}
    };
    window.addEventListener('beforeunload', this._beforeUnload);

    this.$i18n.locale = this.$root.$i18n.locale;
  },

  watch: {
    botId: {
      immediate: false,
      async handler(newId, oldId) {
        if (!newId) {
          console.log('on remove 9');
          this.onRemove();
          return;
        }
        if (newId !== oldId) {
          try {
            await this.$store.dispatch('agentBots/show', newId);

            // console.log('on remove 8');
            // this.onRemove();
            await this.$nextTick();
            // await this.onStart(
            //   this.$store.getters['agentBots/getBot']?.(newId)?.id
            // );
          } catch (e) {
            console.error('agentBots/show (watch) error:', e);
            console.log('on remove 7');
            this.onRemove();
          }
        }
      },
    },
    agentBot: {
      immediate: true,
      async handler(newBot, oldBot) {
        console.log('newBot:', newBot);
        console.log('is not empty:', !!newBot);
        console.log('oldBot:', oldBot);
        console.log('is not empty:', !!oldBot);
        if (
          newBot?.id !== oldBot?.id &&
          oldBot &&
          Object.keys(oldBot).length > 0
        ) {
          console.log('agentBot old');
          console.log('on remove 6');
          this.onRemove();
          return;
        }

        console.log('cleanUp:', this.cleanUp);
        if (!this.cleanUp) {
          console.log('newBot');
          this.agentId = newBot.id || '';
          this.userPrompt = newBot?.prompt || '';
          this.originalPrompt = newBot?.prompt || '';
          this.editorKey++;
          // this.showAgain();
        }
        await this.$nextTick();
      },
    },
  },
  beforeRouteLeave(to, from, next) {
    try {
      console.log('on remove 5');
      this.onRemove();
    } catch (e) {
      console.error('onRemove error:', e);
    }
    next();
  },
  // beforeRouteUpdate(to, from, next) {
  //   try {
  //     console.log('on remove 4');
  //     this.onRemove();
  //   } catch (e) {
  //     console.error('onRemove error:', e);
  //   }
  //   next();
  // },
  beforeDestroy() {
    window.removeEventListener('beforeunload', this._beforeUnload);
    try {
      console.log('on remove 3');
      this.onRemove();
    } catch (e) {
      console.error('onRemove error:', e);
    }
  },
  async activated() {
    this.cleanUp = false;
    console.log('cleanUp from activated:', this.cleanUp);
    console.log('onStart');
    console.log('botId:', this.botId);
    await this.onStart(
      this.$store.getters['agentBots/getBot']?.(this.botId)?.id
    );
  },
  deactivated() {
    try {
      console.log('on remove 2');
      this.onRemove();
    } catch (e) {
      console.error('onRemove error:', e);
    }
  },

  methods: {
    resetAgentState() {
      console.log('resetAgentState');
      this.agentId = '';
      this.editorKey++;
      this.hasStarted = false;
      this.isRunning = false;
      this.injectError = null;
      // Opcional si quieres limpiar todo:
      // this.scriptContent = '';
      // this.website = null;
      // this.cleanupDone = false;
    },

    normalizeContent(val) {
      return (val || '')
        .replace(/&nbsp;/g, ' ')
        .replace(/<p><br><\/p>/g, '')
        .replace(/\s+/g, ' ')
        .trim();
    },

    async onStart(agentBotId) {
      if (!this.canStart || agentBotId === undefined || this.hasStarted) return;

      this.isRunning = true;
      this.injectError = null;

      try {
        if (!this.website?.id) {
          const website = await this.$store.dispatch(
            'inboxes/createWebsiteChannel',
            {
              name: 'Agente de Prueba',
              greeting_enabled: false,
              greeting_message: 'Hi there!',
              channel: {
                type: 'web_widget',
                website_url: 'http://localhost:3000/',
                widget_color: '#009CE0',
                welcome_title: 'Agente de Prueba!',
                welcome_tagline:
                  'Bienvenido al entorno de prueba de Agente de Prueba',
              },
            }
          );
          this.website = website || null;
          this.scriptContent = website?.web_widget_script || '';
        } else {
          this.scriptContent =
            this.website?.web_widget_script || this.scriptContent;
        }

        if (this.website?.id && agentBotId) {
          await this.$store.dispatch('agentBots/setAgentBotInbox', {
            inboxId: this.website.id,
            botId: agentBotId,
          });
          this.showAgain();
          this.injectWidgetScript(this.scriptContent);
          this.hasStarted = true;
        } else {
          throw new Error('Missing agentBotId or websiteId');
        }
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
        this.originalPrompt = this.userPrompt;
      } catch (e) {
        console.log('updateAgent error:', e);
      } finally {
        this.isUpdatingAgent = false;
      }
    },

    onRemove() {
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

      console.log('resetAgentState 5');
      this.cleanUp = true;
      this.resetAgentState();
    },

    removeScript() {
      document
        .querySelectorAll( 'iframe[src*="easycontact.top"], iframe[src*="localhost:3000"], iframe[id^="woot-"], iframe[name^="woot-"]' ) .forEach(el => el.remove()); document .querySelectorAll('[class*="woot-widget-holder"]') .forEach(el => el.remove()); document .querySelectorAll('[class*="woot--bubble-holder"]') .forEach(el => el.remove());
      document.querySelectorAll('[class*="woot-widget-holder"]').forEach(el => {
        el.innerHTML = ''; // borra contenido interno
        el.removeAttribute('style');
        el.className = '';
      });
      document
        .querySelectorAll('[class*="woot--bubble-holder"]')
        .forEach(el => {
          el.innerHTML = '';
          el.removeAttribute('style');
          el.className = '';
        });
    },

    // por si necesitas revertirlo:
    showAgain() {
      const selectors = [
        '[class*="woot-widget-holder"]',
        '[class*="woot--bubble-holder"]',
        'iframe[src*="easycontact.top"]',
        'iframe[src*="localhost:3000"]',
        'iframe[id^="woot-"]',
        'iframe[name^="woot-"]',
      ].join(', ');

      const style = document.getElementById('woot-hide-style');
      if (style) {
        style.textContent = `
      ${selectors} {
        display: initial !important;
        visibility: visible !important;
        opacity: 1 !important;
        pointer-events: auto !important;
      }
    `;
      }
    },

    async injectWidgetScript(rawScript) {
      // this.removeScript();
      if (!rawScript) return;

      const decoded = rawScript
        .replace(/\\u003c/g, '<')
        .replace(/\\u003e/g, '>');
      const match = decoded.match(/<script[^>]*>([\s\S]*?)<\/script>/i);
      let code = match ? match[1] : decoded;

      code = code.replace(
        /var BASE_URL\s*=\s*["']https:\/\/www\.easycontact\.top["'];/,
        'var BASE_URL="http://localhost:3000";'
      );

      const blob = new Blob([code], { type: 'text/javascript' });
      const src = URL.createObjectURL(blob);

      const script = document.createElement('script');
      script.setAttribute('name', SCRIPT_NAME);
      script.type = 'text/javascript';
      script.src = src;
      script.async = true;

      script.onload = () => {
        URL.revokeObjectURL(src);

        const observer = new MutationObserver(() => {
          const bubble = document.querySelector(
            '.woot-widget-bubble.woot-elements--right'
          );
          if (bubble) {
            bubble.click();
            observer.disconnect();
          }
        });

        observer.observe(document.body, { childList: true, subtree: true });
      };

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
      } finally {
        this.website = null;
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
            {{ $t('AGENTS_AI.MODALS.SANDBOX.TITLE') }}
          </h2>
          <p class="text-slate-500 text-sm">
            {{ $t('AGENTS_AI.MODALS.SANDBOX.SUBTITLE') }}
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
            {{ $t('AGENTS_AI.MODALS.SANDBOX.LOADING_AGENT') }}
          </span>
        </div>

        <label for="userPrompt" class="block font-semibold mb-2">
          {{ $t('AGENTS_AI.MODALS.SANDBOX.USER_PROMPT_LABEL') }}
        </label>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-3">
          <div class="md:col-span-2">
            <TinyEditor v-model="userPrompt" :key="editorKey" />
          </div>

          <aside class="space-y-2">
            <div
              class="bg-slate-50 border border-slate-200 rounded-xl p-4 dark:bg-slate-800 dark:border-slate-700"
            >
              <h3 class="text-sm font-bold mb-2">
                {{ $t('AGENTS_AI.MODALS.SANDBOX.INSTRUCTIONS_TITLE') }}
              </h3>
              <ul
                class="list-disc pl-5 text-slate-700 dark:text-slate-200 space-y-1 text-sm leading-relaxed"
              >
                <li>{{ $t('AGENTS_AI.MODALS.SANDBOX.BULLET_CONFIGURE') }}</li>
                <li>{{ $t('AGENTS_AI.MODALS.SANDBOX.BULLET_TRY') }}</li>
                <li>{{ $t('AGENTS_AI.MODALS.SANDBOX.BULLET_MONITOR') }}</li>
                <li>{{ $t('AGENTS_AI.MODALS.SANDBOX.BULLET_TUNE') }}</li>
              </ul>
              <p v-if="injectError" class="mt-2 text-xs text-red-600">
                {{ injectError }}
              </p>
            </div>

            <woot-button
              color-scheme="primary"
              class="w-full mt-2 text-center"
              size="expanded"
              is-expanded
              :disabled="!agentBot || isUpdatingAgent || !isDirty"
              @click="updateAgent"
            >
              <template v-if="isUpdatingAgent">
                {{ $t('COMMON.SAVING') }}…
              </template>
              <template v-else>
                {{ $t('AGENTS_AI.MODALS.SANDBOX.BUTTON_SET_CONFIG') }}
              </template>
            </woot-button>
          </aside>
        </div>
      </section>
    </div>
  </div>
</template>
