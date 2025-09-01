<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

export default {
  components: { WootSubmitButton, Modal, WootMessageEditor },
  props: {
    responseContent: {
      type: String,
      default: '',
    },
    onClose: {
      type: Function,
      default: () => { },
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      show: true,
    };
  },
  validations: {
  },
  methods: {
  },
};
</script>

<template>

  <!--? Open Button -->
  <!-- <woot-modal :show.sync="showAgentRag" :on-close="hideAgentRag">
      <AgentRag :on-close="hideAgentRag" />
    </woot-modal> -->
  <!--? Open Button -->


  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.RAG.NAME')"
        :header-content="$t('AGENTS_AI.CARDS.RAG.DESCRIPTION')" />

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
