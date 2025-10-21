<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'dashboard/composables/useI18n';
import { useAlert } from 'dashboard/composables';
import { computed, ref, onBeforeMount } from 'vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import AddSorter from './AddSorter.vue';
import EditSorter from './EditSorter.vue';

const { t } = useI18n();
const getters = useStoreGetters();
const store = useStore();

const records = computed(() => getters['sorter/getSorters'].value);
const uiFlags = computed(() => getters['sorter/getUIFlags'].value);
const deleteMessage = computed(() => ` ${selectedLabel.value.name}?`);

const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedLabel = ref({});
const loading = ref({});

const openAddPopup = () => {
    showAddPopup.value = true;
};

const hideAddPopup = () => {
    showAddPopup.value = false;
};

const openEditPopup = value => {
    showEditPopup.value = true;
    selectedLabel.value = value;
};

const hideEditPopup = () => {
    showEditPopup.value = false;
};

const openDeletePopup = value => {
    showDeleteConfirmationPopup.value = true;
    selectedLabel.value = value;
};

const closeDeletePopup = () => {
    showDeleteConfirmationPopup.value = false;
};

const deleteSorter = async id => {
    try {
        await store.dispatch('sorter/delete', id);
        useAlert(t('SORTER.DELETE.API.SUCCESS_MESSAGE'));
    } catch (error) {
        const errorMessage = error?.message || t('SORTER.DELETE.API.ERROR_MESSAGE');
        useAlert(errorMessage);
    } finally {
        loading.value[selectedLabel.value.id] = false;
    }
};

const confirmDeletion = () => {
    loading.value[selectedLabel.value.id] = true;
    closeDeletePopup();
    deleteSorter(selectedLabel.value.id);
};

onBeforeMount(() => {
    store.dispatch('sorter/get');
});

</script>

<template>
    <SettingsLayout :is-loading="uiFlags.isFetching" :loading-message="$t('SORTER.LOADING')"
        :no-records-found="!records.length" :no-records-message="$t('SORTER.LIST.404')">
        <template #header>
            <BaseSettingsHeader :title="$t('SORTER.HEADER')" :description="$t('SORTER.DESCRIPTION')"
                :link-text="$t('SORTER.LEARN_MORE')" feature-name="labels">
                <template #actions>
                    <woot-button class="button nice rounded-md" icon="add-circle" @click="openAddPopup">
                        {{ $t('SORTER.HEADER_BTN_TXT') }}
                    </woot-button>
                </template>
            </BaseSettingsHeader>
        </template>
        <template #body>
            <table class="min-w-full overflow-x-auto divide-y divide-slate-75 dark:divide-slate-700">
                <thead>
                    <th v-for="thHeader in $t('SORTER.LIST.TABLE_HEADER')" :key="thHeader"
                        class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-slate-700 dark:text-slate-300">
                        {{ thHeader }}
                    </th>
                </thead>
                <tbody>
                    <tr v-for="(sorter, index) in records" :key="sorter.name">
                        <td class="py-4 ltr:pr-4 rtl:pl-4">
                            <span class="font-medium break-words text-slate-700 dark:text-slate-100 mb-1">
                                {{ sorter.name }}
                            </span>
                        </td>
                        <td class="py-4 ltr:pr-4 rtl:pl-4">{{ sorter.description }}</td>
                        <td class="leading-6 py-4 ltr:pr-4 rtl:pl-4">
                            <div class="flex items-center">
                                <span
                                    class="rounded h-4 w-4 mr-1 rtl:mr-0 rtl:ml-1 border border-solid border-slate-50 dark:border-slate-700"
                                    :style="{ backgroundColor: sorter.color }" />
                                {{ sorter.color }}
                            </div>
                        </td>
                        <td class="py-4 min-w-xs">
                            <div class="flex gap-1">
                                <woot-button v-tooltip.top="$t('SORTER.FORM.EDIT')" variant="smooth" size="tiny"
                                    color-scheme="secondary" class-names="grey-btn" :is-loading="loading[sorter.id]"
                                    icon="edit" @click="openEditPopup(sorter)" />
                                <woot-button v-tooltip.top="$t('SORTER.FORM.DELETE')" variant="smooth"
                                    color-scheme="alert" size="tiny" icon="dismiss-circle" class-names="grey-btn"
                                    :is-loading="loading[sorter.id]" @click="openDeletePopup(sorter, index)" />
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </template>

        <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
            <AddSorter @close="hideAddPopup" />
        </woot-modal>

        <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
            <EditSorter :selected-response="selectedLabel" @close="hideEditPopup" />
        </woot-modal>

        <woot-delete-modal :show.sync="showDeleteConfirmationPopup" :on-close="closeDeletePopup"
            :on-confirm="confirmDeletion" :title="$t('SORTER.DELETE.CONFIRM.TITLE')"
            :message="$t('SORTER.DELETE.CONFIRM.MESSAGE')" :message-value="deleteMessage"
            :confirm-text="$t('SORTER.DELETE.CONFIRM.YES')" :reject-text="$t('SORTER.DELETE.CONFIRM.NO')" />
    </SettingsLayout>
</template>
