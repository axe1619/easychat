<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from '../../../../../../components/buttons/FormSubmitButton.vue';
import Spinner from 'shared/components/Spinner.vue';

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
                // this.v$.fileDescription.$invalid
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
            errorFileDescription: false,
            uploading: false,
            error: null,
            progress: null
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
            required
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

            if(this.fileDescription.trim() === ''){
                this.errorFileDescription = true
                return
            }

            const uploadId = crypto.randomUUID(); // cualquier id único por subida
            const es = new EventSource(`${process.env.AGENTIC_EASY_CONTACT}/api/rag/progress/${uploadId}`);

            es.addEventListener('progress', (ev) => {
                const { chunks, uploaded } = JSON.parse(ev.data);
                this.progress = `Subiendo datos del archivo: ${uploaded} / ${chunks}`
            });

            es.addEventListener('done', () => {
                console.log('Procesamiento terminado');
                this.progress = null
                es.close();
            });

            es.addEventListener('error', (e) => {
                console.warn('SSE error', e);
                this.progress = null
                es.close();
            });

            const fd = new FormData()
            fd.append('collectionName', collectionName)
            fd.append('uploadId', uploadId)
            fd.append('file', this.file, this.file.name)

            try {
                this.uploading = true
                this.progress = `Procesando archivo`
                const res = await axios.post(`${process.env.AGENTIC_EASY_CONTACT}/api/rag/add-pdf`, fd, {
                    headers: { 'Content-Type': 'multipart/form-data' },
                    maxBodyLength: Infinity
                },
                )

                console.log(res)

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
            } catch (err) {
                console.log(err)
                const error = err?.response?.data?.error || err.message || 'Error de red';
                if (err?.response?.status === 409) this.error = this.$t('AGENTS_AI.ALERT.RAG.CREATE.UNIQUE_ERROR');
                else {
                    this.error = error;
                    useAlert(this.$t('AGENTS_AI.ALERT.RAG.CREATE.ERROR'))
                }
                setTimeout(() => { this.error = null }, '8000')
            } finally {
                this.uploading = false
                this.progress = null
                this.errorFileDescription = false
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

            <label for="file-instruction">{{$t('AGENTS_AI.CARDS.RAG.FORM.LABEL_DESCRIPTION')}}</label>
            <textarea v-model="fileDescription" id="file-instruction"
                :placeholder="$t('AGENTS_AI.CARDS.RAG.FORM.PLACEHOLDER_DESCRIPTION')"
            />
            <span v-if="errorFileDescription" class="text-sm font-semibold text-[#F2555A] mb-2">
                {{$t('AGENTS_AI.CARDS.RAG.FORM.ERROR_DESCRIPTION')}}
            </span>

            <div class="flex flex-col">
                <label>
                    {{ $t('AGENTS_AI.CARDS.RAG.FORM.LABEL_FILE') }}
                    <input type="file" accept=".pdf" multiple @change="onFileChange" />
                </label>
            </div>

            <div class="flex flex-row justify-end items-center w-full gap-2 px-0 py-2">

                <span v-if="error" class="text-sm text-red-400 dark:text-red-500 me-auto font-medium">{{ error }}</span>
                <span v-if="progress !== !error" class="text-sm text-blue-500 me-auto font-medium">{{ progress }}</span>

                <!-- <span v-if="success && !error" class="text-sm text-green-400 dark:text-green-500 me-auto font-medium">{{
                    success }}</span> -->
                <WootSubmitButton :disabled="isButtonDisabled || uploading"
                    :button-text="$t('AGENTS_AI.CARDS.RAG.FORM.SUBMIT')" :loading="uploading" />
                <button class="button clear" @click.prevent="toggleAddNewFile" :disabled="uploading">
                    {{ $t('AGENTS_AI.CARDS.RAG.FORM.CANCEL') }}
                </button>
            </div>
        </form>
    </div>
</template>