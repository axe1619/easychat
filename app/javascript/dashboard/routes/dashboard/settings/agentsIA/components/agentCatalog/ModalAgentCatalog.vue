<script>
import { mapGetters } from 'vuex';
import WootSubmitButton from '../../../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import ImportCatalog from './ImportCatalog.vue';

export default {
  name: 'ModalAgentCatalog',
  components: { WootSubmitButton, Modal, WootMessageEditor, ImportCatalog },
  props: {
    responseContent: {
      type: String,
      default: '',
    },
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
    }
  },
  computed: {
    ...mapGetters({
      agentBots: 'agentBots/getBots',
      catalogs: 'catalogs/getCatalogs',
    }),
    agentCatalogs() {
      return this.$store.getters['catalogs/getCatalogsByAgentBotId'](Number(this.botId));
    },
    headersCatalogs() {
      return ['codigo', 'nombre', 'descripcion', 'descripcion_larga', 'categoria', 'subcategoria', 'precio', 'moneda', 'unidad_medida', 'presentacion', 'stock_disponible', 'stock_minimo', 'descuento', 'precio_oferta', 'impuesto', 'estado', 'marca', 'proveedor', 'codigo_barras', 'imagen_url', 'galeria_imagenes', 'ficha_tecnica_url', 'manual_url', 'video_url', 'pais_origen', 'garantia', 'fecha_creacion', 'fecha_actualizacion', 'etiquetas', 'politicas_envio', 'politicas_devolucion', 'variantes', 'relacionados', 'ratings']
    },
  },
  mounted() {
    this.$store.dispatch('catalogs/get', { agent_bot_id: this.botId });
  },
  data() {
    return {
      show: true,
      importCatalog: false,
    };
  },
  validations: {
  },
  methods: {
    toggleImportCatalog() {
      this.importCatalog = !this.importCatalog;
    },
    exportCatalog() {
      console.log('export-catalog');
    },
    getCatalogs() {
      console.log('agentCatalogs:',this.agentCatalogs)
      console.log('headersCatalogs:',this.headersCatalogs)
    }
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">

    <ImportCatalog v-if="importCatalog" :toggle-import-catalog="toggleImportCatalog" :account-id="accountId"
      :bot-id="botId" />

    <div v-else class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.CATALOG.NAME')"
        :header-content="$t('AGENTS_AI.CARDS.RAG.DESCRIPTION')" />

      <div class="mx-8 mb-3 flex">
        <woot-button color-scheme="info" icon="upload" class="clear [&>span]:hidden xs:[&>span]:block"
          @click="toggleImportCatalog">
          {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_IMPORT') }}
        </woot-button>

        <!-- <woot-button color-scheme="info" icon="download" class="clear [&>span]:hidden xs:[&>span]:block"
          @click="exportCatalog">
          {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_EXPORT') }}
        </woot-button> -->
      </div>
      <!-- <button class="button clear" @click="getCatalogs">GET...</button> -->

      <div v-if="agentCatalogs.length" class="overflow-scroll border rounded mx-8 mb-8 max-h-96">
        <table class="min-w-full border-collapse">
          <thead class="bg-slate-600 sticky top-0 z-10">
            <tr>
              <th v-for="(h, i) in headersCatalogs" :key="i" class="text-left p-2 border-b">
                {{ h }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(r, ri) in agentCatalogs" :key="ri">
              <td v-for="(h, ci) in headersCatalogs" :key="ci" class="p-2 border-b">
                {{ r[h] }}
              </td>
            </tr>
          </tbody>
        </table>
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
