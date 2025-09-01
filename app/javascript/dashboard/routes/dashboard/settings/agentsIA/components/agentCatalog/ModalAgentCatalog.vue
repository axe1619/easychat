<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import WootSubmitButton from '../../../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import ImportCatalog from './ImportCatalog.vue';

export default {
  name:'ModalAgentCatalog',
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
  setup() {
    return { v$: useVuelidate() };
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
    toggleImportCatalog(){
      this.importCatalog = !this.importCatalog;
    },
    exportCatalog(){
      console.log('export-catalog');
    }
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">

    <ImportCatalog  v-if="importCatalog" :toggle-import-catalog="toggleImportCatalog" :account-id="accountId"
      :bot-id="botId"/>

    <div v-else class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.CATALOG.NAME')"
        :header-content="$t('AGENTS_AI.CARDS.RAG.DESCRIPTION')" />

        <div class="mx-8 mb-3 flex" >
          <woot-button
              color-scheme="info"
              icon="upload"
              class="clear [&>span]:hidden xs:[&>span]:block"
              @click="toggleImportCatalog"
            >
              {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_IMPORT') }}
            </woot-button>
  
            <woot-button
              color-scheme="info"
              icon="download"
              class="clear [&>span]:hidden xs:[&>span]:block"
              @click="exportCatalog"
            >
              {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_EXPORT') }}
            </woot-button>
        </div>


        <!-- Contenido -->
         
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
