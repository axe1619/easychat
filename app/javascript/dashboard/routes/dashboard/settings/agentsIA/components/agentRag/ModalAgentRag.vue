<script>
import WootSubmitButton from '../../../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../../../components/Modal.vue';
import AddInformationRag from './AddInformationRag.vue';
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import { useAlert } from 'dashboard/composables';

export default {
  components: { WootSubmitButton, Modal, AddInformationRag, Spinner },
  props: {
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
      uiFlags: 'agentBots/getUIFlags',
      rags: 'rags/getRags',
      ragsUI: 'rags/getUIFlags',
    }),
    agentRags() {
      return this.$store.getters['rags/getRagsByAgentBotId'](Number(this.botId));
    },
    isRagUpdating() {
      return this.ragsUI.isUpdating;
    }
  },
  data() {
    return {
      show: true,
      loading: false,
      addNewFile: false,
      idDescription: null,
      idDeleteRag: null,
      valueDescription: '',
      deleteNameRag: '',
      isRagDeleting: false
    };
  },
  mounted() {
    this.$store.dispatch('rags/get', { agent_bot_id: this.botId });
  },
  methods: {
    formatDate(timestamp) {
      const date = new Date(timestamp)
      return date.toLocaleDateString('es-ES', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
      })
    },
    toggleAddNewFile() {
      this.addNewFile = !this.addNewFile;
    },
    activeEditDescription(id, value) {
      this.idDescription = id;
      this.valueDescription = value;
    },
    desactiveEditDescription() {
      this.idDescription = null;
      this.valueDescription = '';
    },
    activeDeleteRag(id, name) {
      this.idDeleteRag = id;
      this.deleteNameRag = name;
    },
    desactiveDeleteRag() {
      this.idDeleteRag = null;
      this.deleteNameRag = '';
    },
    async updateDescriptionRag() {
      const data = {
        id: this.idDescription,
        description: this.valueDescription,
      }
      await this.$store.dispatch('rags/update', data);
      useAlert(this.$t('AGENTS_AI.ALERT.RAG.UPDATE.SUCCESS'));
      this.desactiveEditDescription()
    },
    async deleteRag() {
      const id = this.idDeleteRag;
      const name = `${this.accountId}-${this.botId}-${this.deleteNameRag}`;

      try {
        this.isRagDeleting = true;
        await axios.delete(`${process.env.AGENTIC_EASY_CONTACT}/api/rag/delete-collection/${name}`);
        await this.$store.dispatch('rags/delete', id);
        useAlert(this.$t('AGENTS_AI.ALERT.RAG.DELETE.SUCCESS'));
      } catch (err) {
        console.log(err)
        console.log('code:', err?.response?.status)
        if(err?.response?.status === 404){
          await this.$store.dispatch('rags/delete', id);
          useAlert(this.$t('AGENTS_AI.ALERT.RAG.DELETE.SUCCESS'));
        }else{
          useAlert(this.$t('AGENTS_AI.ALERT.RAG.DELETE.ERROR'));
        }
      } finally {
        this.isRagDeleting = false;
      }
    },
    getRags() {
      console.log('RAGs:', this.agentRags);
    }
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">

    <!-- <div class="flex">
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="dismiss"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="arrow-redo"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="clipboard"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="arrow-clockwise"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="list"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="mail"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="person"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="snooze"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="info"/>
      <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="book-clock"/>
    </div> -->

    <AddInformationRag v-if="addNewFile" :toggle-add-new-file="toggleAddNewFile" :account-id="accountId"
      :bot-id="botId" />

    <div v-else class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.RAG.NAME')"
        :header-content="$t('AGENTS_AI.CARDS.RAG.DESCRIPTION')" />

      <div class="flex flex-row w-full gap-2 px-8 py-2">
        <button class="button clear" @click.prevent="toggleAddNewFile">
          {{ $t('AGENTS_AI.CARDS.RAG.ADD') }}
        </button>
        <!-- <button class="button clear" type="button" @click="getRags">GET RAGS...</button> -->
      </div>
      <div class="px-8 pb-8">
        <table class="divide-y divide-slate-75 dark:divide-slate-700">
          <thead class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300">
            <tr>
              <th class="text-center">ID</th>
              <th class="text-center">FECHA</th>
              <th class="text-center">DESCRIPCION</th>
              <th class="text-center">ACCION</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300">
            <tr v-if="this.loading">
              <td colspan="4" class="py-4">
                <div class="flex justify-center items-center">
                  <Spinner />
                </div>
              </td>
            </tr>
            <tr v-else v-for="item in agentRags" :key="item.id">
              <td class="py-4 text-center">{{ item.collection_name }}</td>
              <td class="py-4 text-center">{{ formatDate(item.created_at) }}</td>
              <td class="py-4 text-center">

                <input v-if="item.id === idDescription" v-model="valueDescription" type="text"
                  class="!m-0 !text-sm !py-1 !h-auto"
                  :placeholder="$t('AGENTS_AI.CARDS.RAG.FORM.PLACEHOLDER_DESCRIPTION')" />
                <span v-else> {{ item.description }}</span>
              </td>
              <td class="py-4">
                <!-- Loading mode-->
                <div v-if="isRagUpdating || isRagDeleting" class="flex justify-evenly items-center">
                  <Spinner />
                </div>
                <!-- Edit mode-->
                <div v-else-if="item.id === idDescription" class="flex justify-evenly items-center">
                  <woot-button size="tiny" variant="smooth" color-scheme="success" icon="checkmark"
                    @click="updateDescriptionRag" />
                  <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="dismiss"
                    @click="desactiveEditDescription" />
                </div>
                <!-- Delete mode-->
                <div v-else-if="item.id === idDeleteRag" class="flex justify-evenly items-center">
                  <woot-button size="tiny" variant="smooth" color-scheme="success" icon="checkmark"
                    @click="deleteRag" />
                  <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="dismiss"
                    @click="desactiveDeleteRag" />
                </div>

                <div v-else class="flex justify-evenly items-center">
                  <woot-button size="tiny" variant="smooth" color-scheme="primary" icon="edit"
                    @click="activeEditDescription(item.id, item.description)" />
                  <woot-button size="tiny" variant="smooth" color-scheme="alert" icon="delete"
                    @click="activeDeleteRag(item.id, item.collection_name)" />
                </div>
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
