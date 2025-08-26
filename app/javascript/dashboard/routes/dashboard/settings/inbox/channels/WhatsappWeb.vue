<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import WhatsappInstancesClient from '../../../../../../dashboard/api/channel/whatsappInstancesClient';

export default {
  components: {
    PageHeader,
  },
  data() {
    return {
      provider: 'whatsapp_cloud',
      qrCode: '',
      errorMessage: '',
      connectionState: 'Desconectado',
      phoneNumber: '',
      inboxName: '',
      instanceName: null,
      isLoading: false,
      qrGenerated: false,
      qrScanned: false,
      qrImageLoaded: false,
      statusInterval: null,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    sanitizeInput(event) {
      const input = event.target.value;
      const sanitized = input.replace(/[^a-zA-Z0-9_-]/g, '_');
      this.inboxName = sanitized;
    },

    async generateQR() {
      this.errorMessage = '';
      this.qrCode = '';
      this.qrImageLoaded = false;
      this.isLoading = true;
      this.qrScanned = false;

      if (!this.inboxName) {
        this.errorMessage = 'El nombre del inbox es requerido.';
        this.isLoading = false;
        return;
      }

      try {
        if (this.qrGenerated && !this.qrScanned && this.instanceName) {
          const data = await WhatsappInstancesClient.connect(this.instanceName);

          if (data?.status === 'CONNECTED') {
            this.connectionState = 'Conectado';
            this.qrScanned = true;
            this.phoneNumber = data?.phone?.id || '';
            return;
          }

          this.qrCode = data?.qrcode?.base64 || data?.base64 || '';
          this.connectionState = 'Intentando reconectar...';
          this.startStatusPolling();
          return;
        }
        const payload = {
          whatsapp_instance: {
            instance_name: this.inboxName,
            chatwoot_account_id: this.accountId,
            chatwoot_token: this.currentUser.access_token,
            chatwoot_url: 'https://easycontact.top',
            chatwoot_sign_msg: false,
            chatwoot_reopen_conversation: true,
            chatwoot_conversation_pending: true,
          },
        };

        const createRes = await WhatsappInstancesClient.create(payload);
        const created = createRes?.data?.instance || createRes?.data || {};
        this.instanceName = created.instanceName || this.inboxName;
        if (this.instanceName) {
          const data = await WhatsappInstancesClient.connect(this.instanceName);

          if (data?.status === 'open') {
            this.connectionState = 'Conectado';
            this.qrScanned = true;
            this.phoneNumber = data?.phone?.id || '';
            return;
          }

          this.qrCode = data?.base64 || data?.base64 || '';
          if (this.qrCode) {
            this.connectionState = 'QR generado';
            this.qrGenerated = true;
            this.startStatusPolling();
          } else {
            this.errorMessage = 'No se pudo obtener el código QR.';
          }
        } else {
          this.errorMessage = 'No se pudo crear la instancia.';
        }
      } catch (error) {
        console.error('Error al generar/reconectar QR:', error);
        const msg = this.extractErrorMessage(error);
        useAlert(msg);
        this.errorMessage = msg;
        if (/already in use/i.test(msg) && this.inboxName) {
          this.instanceName = this.inboxName;
          try {
            const data = await WhatsappInstancesClient.connect(this.instanceName);

            if (data?.status === 'CONNECTED' || data?.status === 'open') {
              this.connectionState = 'Conectado';
              this.qrScanned = true;
              this.phoneNumber = data?.phone?.id || '';
            } else {
              this.qrCode = data?.qrcode?.base64 || data?.base64 || '';
              if (this.qrCode) {
                this.connectionState = 'QR generado';
                this.qrGenerated = true;
                this.startStatusPolling();
              }
            }
          } catch (e2) {
            const msg2 = this.extractErrorMessage(e2);
            useAlert(msg2);
            this.errorMessage = msg2;
          }
        }
      } finally {
        this.isLoading = false;
      }
    },
    extractErrorMessage(error) {
      const data = error?.response?.data ?? error?.data ?? error;
      const tryParse = val => {
        if (typeof val === 'string') {
          try { return JSON.parse(val); } catch { /* noop */ }
        }
        return val;
      };

      const body = tryParse(data?.body) || tryParse(data);
      const rawMsg = body?.response?.message ?? data?.response?.message;
      if (Array.isArray(rawMsg)) {
        const flat = rawMsg.flat ? rawMsg.flat(Infinity) : [].concat(...rawMsg);
        if (flat.length) return String(flat[0]);
      }
      if (rawMsg) return String(rawMsg);

      if (body?.error) return String(body.error);
      if (data?.error) return String(data.error);
      if (data?.message) return String(data.message);
      if (error?.message) return String(error.message);

      return 'Error desconocido';
    },

    startStatusPolling() {
      if (this.statusInterval) clearInterval(this.statusInterval);
      if (!this.instanceName) return;

      this.statusInterval = setInterval(async () => {
        try {
          const { data } = await WhatsappInstancesClient.connectionState(
            this.instanceName
          );

          if (data?.instance?.state === 'open') {
            this.connectionState = 'Conectado';
            this.qrScanned = true;
            this.phoneNumber = data?.phone?.id || '';
            clearInterval(this.statusInterval);
            this.statusInterval = null;
          }
        } catch (err) {
          console.error('Error en polling de estado:', this.extractErrorMessage(err));
        }
      }, 3000);
    },

    async createChannel() {
      try {
        await this.setWebhook();
        const apiChannel = await this.$store.dispatch('inboxes/createChannel', {
          name: this.inboxName,
          channel: {
            type: 'api',
            webhook_url: `http://34.41.191.74:3030/chatwoot/webhook/${this.inboxName}`,
          },
        });
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: apiChannel.id,
          },
        });
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPPWEB.API.ERROR_MESSAGE'));
      }
    },

    async setWebhook() {
      if (!this.instanceName) {
        useAlert('Primero crea/conecta la instancia.');
        return;
      }

      const payload = {
        enabled: true,
        accountId: String(this.accountId),
        token: this.currentUser.access_token,
        signMsg: false,
        sign_delimiter: '\n',
        reopenConversation: true,
        conversationPending: true,
        import_contacts: false,
        import_messages: false,
        days_limit_import_messages: 0,
        auto_create: true,
      };

      await WhatsappInstancesClient
        .setWebhook(this.instanceName, payload)
        .then(r => (r && r.data ? r.data : r));
    }

  },

  beforeDestroy() {
    if (this.statusInterval) {
      clearInterval(this.statusInterval);
      this.statusInterval = null;
    }
  },
};
</script>

<template>
  <div class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPPWEB.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPPWEB.DESC')"
    />

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label class="flex flex-col gap-2">
        <span>{{ $t('INBOX_MGMT.ADD.WHATSAPPWEB.INBOX_NAME.LABEL') }}:</span>
        <div class="flex gap-2">
          <input
            type="text"
            class="border p-2 rounded-md"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPPWEB.INBOX_NAME.PLACEHOLDER')"
            v-model="inboxName"
            @input="sanitizeInput"
            @keyup.enter="generateQR"
            required
          />
          <button
            v-if="!qrScanned"
            @click="generateQR"
            class="px-4 py-2 bg-green-600 text-white rounded"
            :disabled="isLoading"
          >
            <span>{{ qrGenerated && !qrScanned ? 'Reconectar QR' : 'Generar QR' }}</span>
          </button>
        </div>
        <span v-if="qrImageLoaded && connectionState !== 'Conectado'">Escanee el código QR:</span>
        <p v-if="isLoading">Cargando...</p>
        <p v-if="errorMessage" class="text-red-500">{{ errorMessage }}</p>

        <img
          v-if="qrCode && connectionState !== 'Conectado'"
          :src="qrCode"
          alt="Código QR"
          class="border p-2 rounded-md w-[300px] h-[300px]"
          @load="qrImageLoaded = true"
          @error="qrImageLoaded = false"
        />

        <p v-if="qrScanned" class="text-green-600 font-bold mt-2">QR Escaneado correctamente</p>
      </label>

      <div class="w-full mt-4">
        <button
          @click="createChannel"
          class="px-4 py-2 bg-green-600 text-white rounded"
          :disabled="!qrScanned"
        >
          Crear canal
        </button>
      </div>
    </div>
  </div>
</template>
