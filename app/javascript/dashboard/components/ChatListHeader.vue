<script setup>
import { ref, computed } from 'vue';
import ConversationBasicFilter from './widgets/conversation/ConversationBasicFilter.vue';
import whatsappInstancesClient from '../api/channel/whatsappInstancesClient';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  pageTitle: { type: String, required: true },
  hasAppliedFilters: { type: Boolean, required: true },
  hasActiveFolders: { type: Boolean, required: true },
  activeStatus: { type: String, required: true },
});

const checking = ref(false);
const connectionStatus = ref('unknown');
const lastError = ref('');
const showQR = ref(false);
const qrCode = ref('');
const qrImageLoaded = ref(false);
const connectionState = ref('');
const acting = ref(false);

const emit = defineEmits([
  'addFolders',
  'deleteFolders',
  'resetFilters',
  'basicFilterChange',
  'filtersModal',
  'foldersModal', // lo usas en el template
]);

const onBasicFilterChange = (value, type) => {
  emit('basicFilterChange', value, type);
};

const hideQR = () => {
  showQR.value = false;
};

const normalizeState = data => {
  const raw = (data?.state || data?.connection || '').toString().toLowerCase();
  if (['connected', 'open', 'online'].includes(raw)) return 'connected';
  if (['disconnected', 'closed', 'offline', 'qr'].includes(raw)) return 'disconnected';
  if (data === true) return 'connected';
  if (data === false) return 'disconnected';
  return 'unknown';
};

const checkState = async () => {
  checking.value = true;
  lastError.value = '';
  try {
    const { data } = await whatsappInstancesClient.connectionState(props.pageTitle);
    connectionStatus.value = normalizeState(data);
  } catch (e) {
    lastError.value = e?.response?.data?.error || e?.message || 'Error consultando estado';
    connectionStatus.value = 'unknown';
  } finally {
    checking.value = false;
  }
};

const restartInstance = async () => {
  acting.value = true;
  lastError.value = '';
  try {
    await whatsappInstancesClient.restart(props.pageTitle);
    useAlert('Instancia reiniciada.');
  } catch (e) {
    lastError.value = e?.response?.data?.error || e?.message || 'Error al reiniciar';
    console.log(lastError.value, 'error');
  } finally {
    acting.value = false;
  }
};

const logoutInstance = async () => {
  acting.value = true;
  lastError.value = '';
  try {
    await whatsappInstancesClient.logout(props.pageTitle);
    await checkState();
    await createQr();
  } catch (e) {
    lastError.value = e?.response?.data?.error || e?.message || 'Error al cerrar sesión';
    console.log(lastError.value, 'error');
  } finally {
    acting.value = false;
  }
};

const createQr = async () => {
  try {
    const data = await whatsappInstancesClient.connect(props.pageTitle);

    if (data?.status === 'CONNECTED') {
      connectionState.value = 'Conectado';
      showQR.value = false;
      return;
    }

    qrCode.value = data?.qrcode?.base64 || data?.base64 || '';
    connectionState.value = 'Intentando reconectar...';
    showQR.value = true;
  } catch (e) {
    lastError.value = e?.response?.data?.error || e?.message || 'Error generando QR';
  }
};

const hasAppliedFiltersOrActiveFolders = computed(
  () => props.hasAppliedFilters || props.hasActiveFolders
);
</script>

<template>
  <div
    class="flex items-center justify-between px-4 py-0"
    :class="{
      'pb-3 border-b border-slate-75 dark:border-slate-700': hasAppliedFiltersOrActiveFolders,
    }"
  >
    <div class="flex max-w-[85%] justify-center items-center">
      <h1
        class="text-xl font-medium break-words truncate text-black-900 dark:text-slate-100"
        :title="props.pageTitle"
      >
        {{ props.pageTitle }}
      </h1>

      <span
        v-if="!hasAppliedFiltersOrActiveFolders"
        class="p-1 my-0.5 mx-1 rounded-md capitalize bg-slate-50 dark:bg-slate-800 text-xxs text-slate-600 dark:text-slate-300"
      >
        {{ $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${props.activeStatus}.TEXT`) }}
      </span>

      <woot-button
        v-if="connectionStatus !== 'disconnected'"
        v-tooltip.bottom="$t('Reiniciar instancia')"
        size="tiny"
        variant="smooth"
        color-scheme="secondary"
        icon="sync"
        :is-loading="acting"
        :disabled="checking"
        @click="restartInstance"
      />
      <woot-button
        v-if="connectionStatus !== 'disconnected'"
        v-tooltip.bottom="$t('Cerrar sesión para reconectar por QR')"
        size="tiny"
        variant="smooth"
        color-scheme="alert"
        icon="power"
        :is-loading="acting"
        :disabled="checking"
        @click="logoutInstance"
      />
      <woot-button
        v-if="connectionStatus === 'disconnected'"
        variant="smooth"
        color-scheme="secondary"
        size="tiny"
        @click="emit('foldersModal')"
      >
        Conectar
      </woot-button>
    </div>

    <div class="flex items-center gap-1">
      <div v-if="props.hasAppliedFilters && !props.hasActiveFolders">
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="save"
          @click="emit('addFolders')"
        />
        <woot-button
          v-tooltip.top-end="$t('FILTER.CLEAR_BUTTON_LABEL')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="dismiss-circle"
          @click="emit('resetFilters')"
        />
      </div>

      <div v-if="props.hasActiveFolders">
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.EDIT.EDIT_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="edit"
          @click="emit('filtersModal')"
        />
        <woot-button
          v-tooltip.top-end="$t('FILTER.CUSTOM_VIEWS.DELETE.DELETE_BUTTON')"
          size="tiny"
          variant="smooth"
          color-scheme="alert"
          icon="delete"
          @click="emit('deleteFolders')"
        />
      </div>

      <woot-button
        v-else
        v-tooltip.right="$t('FILTER.TOOLTIP_LABEL')"
        variant="smooth"
        color-scheme="secondary"
        icon="filter"
        size="tiny"
        @click="emit('filtersModal')"
      />

      <ConversationBasicFilter
        v-if="!hasAppliedFiltersOrActiveFolders"
        @changeFilter="onBasicFilterChange"
      />
    </div>

    <woot-modal :show.sync="showQR" :on-close="hideQR">
      <h3>Nuevo QR generado</h3>
      <br />
      <img
        v-if="qrCode"
        :src="qrCode"
        alt="Código QR"
        class="border p-2 rounded-md w-[300px] h-[300px]"
        @load="qrImageLoaded = true"
        @error="qrImageLoaded = false"
      />
    </woot-modal>
  </div>
</template>
