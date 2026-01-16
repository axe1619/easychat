<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import WootSubmitButton from '../../../../../../components/buttons/FormSubmitButton.vue';
import Spinner from 'shared/components/Spinner.vue';
import { VeTable, VePagination } from 'vue-easytable';

export default {
    components: { WootSubmitButton, Spinner, VeTable, VePagination },
    props: {
        toggleImportCatalog: {
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
            uiFlags: 'catalogs/getUIFlags',
        }),
        botCatalogs() {
            return this.$store.getters['catalogs/getCatalogsByAgentBotId'](Number(this.botId));
        },
        isUpdating() {
            return this.uiFlags.isUpdating;
        },
        isCreating() {
            return this.uiFlags.isCreating;
        },
        isBulkCreating() {
            return this.uiFlags.isBulkCreating;
        },
        isBulkDeleting() {
            return this.uiFlags.isBulkDeleting;
        },
        bulkProgress() {
            return this.uiFlags.bulkProgress;
        }
    },
    mounted() {
        this.$store.dispatch('catalogs/get', { agent_bot_id: this.botId })
        const items = this.$store.getters['catalogs/getCatalogsByAgentBotId'](Number(this.botId))
        this.catalogExists = items.length > 0
    },
    data() {
        return {
            file: null,
            uploading: false,
            error: null,
            validHeaders: ['codigo', 'nombre', 'descripcion', 'descripcion_larga', 'categoria', 'subcategoria', 'precio', 'moneda', 'unidad_medida', 'presentacion', 'stock_disponible', 'stock_minimo', 'descuento', 'precio_oferta', 'impuesto', 'estado', 'marca', 'proveedor', 'codigo_barras', 'imagen_url', 'galeria_imagenes', 'ficha_tecnica_url', 'manual_url', 'video_url', 'pais_origen', 'garantia', 'fecha_creacion', 'fecha_actualizacion', 'etiquetas', 'politicas_envio', 'politicas_devolucion', 'variantes', 'relacionados', 'ratings'],
            headers: [],
            rows: [],
            duplicateCodes: [],
            catalogExists: false
        };
    },
    setup() {
        return { v$: useVuelidate() };
    },
    validations: {
        file: {
            required
        }
    },
    methods: {
        onFileChange(e) {
            this.error = null
            this.headers = []
            this.rows = []
            this.duplicateCodes = []

            const file = e.target.files[0]
            if (!file) return

            // Validación de extension
            const isCsvMime = file.type === 'text/csv' || file.type === 'application/vnd.ms-excel' || file.type === ''
            const isCsvExt = file.name.toLowerCase().endsWith('.csv')
            if (!isCsvMime && !isCsvExt) {
                this.error = this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.FILE_ERROR');
                e.target.value = ''
                return
            }

            const reader = new FileReader()
            reader.onerror = () => {
                this.error = this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.ERROR');
                this.$refs.csvInput && (this.$refs.csvInput.value = '')   // reset de input
            }
            reader.onload = () => {
                const text = this.normalizeText(reader.result)
                try {
                    const { headers, rows } = this.parseCsv(text)
                    this.headers = headers;
                    this.rows = rows;
                    const verify1 = this.verifyHeaders(headers, this.validHeaders);
                    if (verify1 === false) {
                        const verify2 = this.checkRequiredFields(rows);
                        if (verify2 === false) this.duplicateCodes = this.verifyDuplicateCodes(rows);
                    }
                } catch (err) {
                    console.log(err)
                    this.error = this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.ERROR');
                } finally {
                    this.$refs.csvInput && (this.$refs.csvInput.value = '') // reset de input
                }
            }
            reader.readAsText(file, 'utf-8');
        },
        normalizeText(str) {
            // Quita BOM y normaliza saltos de linea
            if (str.charCodeAt(0) === 0xFEFF) {
                str = str.slice(1)
            }
            return str.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
        },
        parseCsv(text) {
            // Parser simple con soporte a comillas y delimitador ; o ,
            // Detecta delimitador (si hay ; mas que , en la primera linea, usa ;)
            const firstLine = text.split('\n')[0] || ''
            const commaCount = (firstLine.match(/,/g) || []).length
            const semiCount = (firstLine.match(/;/g) || []).length
            const delim = semiCount > commaCount ? ';' : ','

            const lines = this.csvTokenizeLines(text, delim)
            if (!lines.length) throw new Error('CSV vacío.')

            const headers = lines[0]
            const rows = []
            for (let i = 1; i < lines.length; i++) {
                const row = {}
                const cols = lines[i]
                if (cols.length === 1 && cols[0] === '') continue // linea vacía
                headers.forEach((h, idx) => {
                    row[h] = cols[idx] ?? ''
                })
                rows.push(row)
            }
            return { headers, rows }
        },
        csvTokenizeLines(text, delim) {
            // Tokeniza respetando comillas "..." y comillas escapadas ""
            const out = []
            let row = []
            let cell = ''
            let inQuotes = false

            const pushCell = () => {
                row.push(cell)
                cell = ''
            }
            const pushRow = () => {
                out.push(row)
                row = []
            }

            for (let i = 0; i < text.length; i++) {
                const ch = text[i]
                const next = text[i + 1]

                if (ch === '"') {
                    if (inQuotes && next === '"') {
                        cell += '"'   // comilla escapada
                        i++           // saltar la segunda
                    } else {
                        inQuotes = !inQuotes
                    }
                } else if (ch === delim && !inQuotes) {
                    pushCell()
                } else if (ch === '\n' && !inQuotes) {
                    pushCell()
                    pushRow()
                } else {
                    cell += ch
                }
            }
            // ultima celda/fila
            pushCell()
            if (row.length) pushRow()
            return out
        },
        verifyHeaders(arr1, arr2) {
            if (arr1.length !== arr2.length) {
                this.error = this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.TABLE_ERROR.HEADER_INCOMPLETE');
                return true;
            }
            if (!arr1.every((val, i) => val === arr2[i])) {
                this.error = this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.TABLE_ERROR.HEADER');
                return true;
            }
            return false;
        },
        verifyDuplicateCodes(rows) {
            const counts = rows.reduce((acc, val) => {
                acc[val.codigo] = (acc[val.codigo] || 0) + 1;
                if (acc[val.codigo] > 1) this.error = this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.TABLE_ERROR.CODES');
                return acc
            }, {})
            return rows.map(val => counts[val.codigo] > 1)
        },
        checkRequiredFields(rows) {
            for (let r = 0; r < rows.length; r++) {
                if (rows[r].codigo === '' || rows[r].nombre === '' || rows[r].descripcion === '') {
                    this.error = this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.TABLE_ERROR.ROW');
                    return true;
                }
            }
            return false;
        },
        async getCatalogs() {
            await this.$store.dispatch('catalogs/get', { agent_bot_id: Number(this.botId) });
            console.log('botCatalogs:', this.botCatalogs)
            console.log('botAccCatalogs:', this.botAccCatalogs)
        },
        async createMany() {
            const items = this.rows.map(r => ({ ...r, account_id: this.accountId, agent_bot_id: this.botId }))
            const { ok, failed } = await this.$store.dispatch('catalogs/createMany', {
                items,
                refreshWith: { agent_bot_id: Number(this.botId), account_id: Number(this.accountId) },
                stopOnError: false,
            })
            useAlert(this.$t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.SUCCESS'))
            this.toggleImportCatalog()
            // console.log('Creados OK:', ok)
            // console.log('Fallidos  :', failed)
        },
        async deleteMany() {
            const ids = this.botCatalogs.map(i => (i.id))
            // console.log('IDs:', ids)
            const { ok, failed } = await this.$store.dispatch('catalogs/deleteMany', {
                ids,
                refreshWith: { agent_bot_id: Number(this.botId), account_id: Number(this.accountId) },
                stopOnError: false,
            });
            // console.log('Eliminados:', ok);
            // console.log('Fallidos:', failed);
        },
        async replaceMany() {
            await this.deleteMany()
            await this.createMany()
        },
        async createOne() {
            const payload = {
                codigo: 'P-002',
                nombre: 'Producto B',
                descripcion: 'Desc B',
                agent_bot_id: this.botId,
                account_id: this.accountId,
                precio: '100',
            };
            await this.$store.dispatch('catalogs/create', payload);
        },
    },
}
</script>
<template>
    <div class="flex flex-col h-auto overflow-auto">
        <woot-modal-header :header-title="$t('AGENTS_AI.CARDS.CATALOG.IMPORT.NAME')">
            <p>{{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.DESCRIPTION_A') }}<a class="text-woot-500 dark:text-woot-500"
                    href="/downloads/import-catalog-sample.csv">{{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.DESCRIPTION_LINK')
                    }}</a>{{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.DESCRIPTION_B') }}
            </p>
        </woot-modal-header>

        <!-- <button class="button clear" @click="getCatalogs">GET...</button> -->

        <div class="flex flex-col w-full px-8 py-8">
            <div class="flex">
                <label class="button primary px-3.5 rounded-[5px] flex cursor-pointer text-xs">
                    <i class="icon ion-paperclip text-base"></i>
                    {{ $t('AGENTS_AI.CARDS.CATALOG.BUTTON_SELECT') }}
                    <input ref="csvInput" type="file" accept=".csv,text/csv" multiple @change="onFileChange"
                        class="hidden" />
                </label>
            </div>

            <div class="flex flex-row justify-end items-center w-full gap-2 px-0 py-2">
                <span v-if="error" class="text-sm text-red-400 dark:text-red-500 me-auto font-medium">{{ error }}</span>
                <span v-if="!error && bulkProgress > 0" class="text-sm text-blue-500 me-auto font-medium">
                    {{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.PROGRESS') }}: {{ bulkProgress }} / {{rows.length}}
                </span>

                <!-- bulkProgress -->
                <button v-if="catalogExists" class="button primary"
                    :disabled="rows.length === 0 || (error !== null) || isBulkCreating || isBulkDeleting" @click="replaceMany">
                    <Spinner v-if="isBulkCreating || isBulkDeleting" />
                    {{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.BUTTON.REPLACE') }}
                </button>
                <button v-else class="button primary" :disabled="rows.length === 0 || (error !== null) || isBulkCreating || isBulkDeleting"
                    @click="createMany">
                    <Spinner v-if="isBulkCreating || isBulkDeleting" />
                    {{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.BUTTON.ADD') }}
                </button>
                <button class="button clear" @click="toggleImportCatalog">
                    {{ $t('AGENTS_AI.CARDS.CATALOG.IMPORT.UPLOAD.BUTTON.CANCEL') }}
                </button>
            </div>
        </div>

        <div v-if="rows.length" class="overflow-scroll border rounded mx-8 mb-8 max-h-96">
            <table class="min-w-full border-collapse">
                <thead class="bg-slate-600 sticky top-0 z-10 text-white">
                    <tr>
                        <th v-for="(h, i) in headers" :key="i" class="text-left p-2 border-b"
                            :class="{ 'bg-red-300': h !== validHeaders[i] }">
                            {{ h }}
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(r, ri) in rows" :key="ri">
                        <td v-for="(h, ci) in headers" :key="ci" class="p-2 border-b"
                            :class="{ 'bg-red-300': ((ci < 3) && (r[h] === '') || ((ci === 0) && duplicateCodes[ri])) }">
                            {{ r[h] }}
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

    </div>
</template>