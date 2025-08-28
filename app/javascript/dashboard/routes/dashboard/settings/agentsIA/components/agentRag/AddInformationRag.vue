<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from '../../../../../../components/buttons/FormSubmitButton.vue';
import Spinner from 'shared/components/Spinner.vue';
import apiAgent from '../../services/apiAgent';

export default {
    components: { WootSubmitButton, Spinner },
    props: {
        toggleAddNewFile: {
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
        isButtonDisabled() {
            return (
                this.v$.file.$invalid ||
                this.v$.fileId.$invalid
            );
        },
        isUpdating() {
            return this.uiFlags.isUpdating;
        },
    },
    data() {
        return {
            file: null,
            fileId: '',
            fileDescription: '',
            uploading: false,
            error: null
        };
    },
    setup() {
        return { v$: useVuelidate() };
    },
    validations: {
        file: {
            required
        },
        fileId: {
            required
        },
        fileDescription: {
            default: ''
        },
    },
    mounted() {
        this.$store.dispatch('rags/get', { agent_bot_id: this.botId });
    },
    methods: {
        onFileChange(event) {
            const file = event.target.files[0]
            if (file && file.type === 'application/pdf') {
                this.file = file
            } else {
                this.file = null
                alert('Solo se permiten archivos PDF')
            }
        },
        async pruebaGet() {
            console.log('RAGs Plain:', this.agentRagsPlain);
            console.log('RAGs:', this.agentRags);
        },
        async pruebaCreate() {
            const collectionName = `${this.accountId}-${this.botId}-${this.fileId}`;
            const data = {
                agent_bot_id: this.botId,
                account_id: this.accountId,
                collection_name: collectionName,
                date: Date.now().toString(),
                description: this.fileDescription,
            }
            try {
                const created = await this.$store.dispatch('rags/create', data);
                console.log('RAG creado:', created);
            } catch (error) {
                console.log('Error', error)
            }

        },
        async submitFile() {
            const collectionName = `${this.accountId}-${this.botId}-${this.fileId}`;
            console.log('Id:', collectionName);
            console.log('Descripcion:', this.fileDescription);
            if (this.file) {
                console.log('Datos del archivo:', {
                    nombre: this.file.name,
                    tamaño: this.file.size,
                    tipo: this.file.type,
                    fecha: this.file.lastModifiedDate,
                })
            }

            const fd = new FormData()
            fd.append('collectionName', collectionName)
            fd.append('file', this.file, this.file.name)

            try {
                this.uploading = true
                await apiAgent.post(`/rag/add-pdf`, fd, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                })
                const data = {
                    agent_bot_id: this.botId,
                    account_id: this.accountId,
                    collection_name: this.fileId,
                    date: Date.now().toString(),
                    description: this.fileDescription
                }
                const created = await this.$store.dispatch('rags/create', data);
                useAlert(this.$t('AGENTS_AI.ALERT.RAG.CREATE.SUCCESS'));
                this.toggleAddNewFile();
                console.log('RAG creado:', created);
            } catch (e) {
                const error = e?.response?.data?.error || e.message || 'Error de red';
                this.error = error;
                console.log('code:',e?.response?.status)
                if(e?.response?.status === 409) this.error = this.$t('AGENTS_AI.ALERT.RAG.CREATE.UNIQUE_ERROR');
                else this.error = this.$t('AGENTS_AI.ALERT.RAG.CREATE.ERROR');

                setTimeout(() => { this.error = null}, '5000')
            } finally {
                this.uploading = false;
            }
        }
    },
}
</script>
<template>
    <div class="flex flex-col h-auto overflow-auto">
        <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.RAG.FORM.NAME')"
            :header-content="$t('AGENTS_AI.CARDS.RAG.FORM.DESCRIPTION')" />

        <!-- <button class="button clear" type="button" @click="pruebaGet"> PRUEBA GET... </button>
        <button class="button clear" type="button" @click="pruebaCreate"> PRUEBA CREATE... </button> -->

        <form class="flex flex-col w-full" @submit.prevent="submitFile()">
            <woot-input v-model="fileId" :label="$t('AGENTS_AI.CARDS.RAG.FORM.LABEL_ID')" type="text"
                :class="{ error: v$.fileId.$error }" :error="v$.fileId.$error
                    ? $t('AGENTS_AI.CARDS.RAG.FORM.ERROR_ID')
                    : ''
                    " :placeholder="$t('AGENTS_AI.CARDS.RAG.FORM.PLACEHOLDER_ID')" @blur="v$.fileId.$touch" />

            <woot-input v-model="fileDescription" :label="$t('AGENTS_AI.CARDS.RAG.FORM.LABEL_DESCRIPTION')" type="text"
                :placeholder="$t('AGENTS_AI.CARDS.RAG.FORM.PLACEHOLDER_DESCRIPTION')"
                @blur="v$.fileDescription.$touch" />

            <div class="flex flex-col">
                <label>
                    {{ $t('AGENTS_AI.CARDS.RAG.FORM.LABEL_FILE') }}
                    <input type="file" accept=".pdf" multiple @change="onFileChange" />
                </label>
            </div>

            <div class="flex flex-row justify-end items-center w-full gap-2 px-0 py-2">

                <span v-if="error" class="text-sm text-red-400 dark:text-red-500 me-auto font-medium">{{ error }}</span>
                
                <!-- <span v-if="success && !error" class="text-sm text-green-400 dark:text-green-500 me-auto font-medium">{{
                    success }}</span> -->
                <WootSubmitButton :disabled="isButtonDisabled || uploading"
                    :button-text="$t('AGENTS_AI.CARDS.RAG.FORM.SUBMIT')" :loading="uploading" />
                <button class="button clear" @click.prevent="toggleAddNewFile">
                    {{ $t('AGENTS_AI.CARDS.RAG.FORM.CANCEL') }}
                </button>
            </div>
        </form>
    </div>
</template>