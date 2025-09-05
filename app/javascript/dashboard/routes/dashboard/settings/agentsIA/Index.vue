<script setup>
import { useI18n } from 'dashboard/composables/useI18n';
import { computed, onMounted } from 'vue';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const avatarDefault = '/assets/images/dashboard/agents-ai/robot.png';

const agentList = computed(() => getters['agentBots/getBots'].value);
const listAgents = () => {
  console.log(agentList.value)
}

onMounted(() => {
  store.dispatch('agentBots/get');
});
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-8 overflow-auto">

    <p class="mb-4 text-base font-normal line-clamp-5 sm:line-clamp-none max-w-3xl tracking-[-0.1px]">{{
      t('AGENTS_AI.HEADER_INDEX.DESCRIPTION') }}</p>

    <div class="flex">
      <div v-for="a in agentList" :key="a.id"
        class="w-60 m-2 bg-white dark:bg-slate-900 cursor-pointer flex flex-col justify-end transition-all duration-200 ease-in px-0 items-center border border-solid border-slate-25 dark:border-slate-800 hover:border-woot-500 dark:hover:border-woot-500 hover:shadow-md rounded">
        <router-link :to="'capabilities?agent=' + a.id" class="w-full h-full p-3 flex flex-col justify-between">
          <div class="w-full h-32 p-2 flex justify-center items-center">
            <img :src="a.avatar_url || avatarDefault" :alt="a.name" class="h-full object-cover" />
          </div>
          <h1 class="text-center font-bold text-slate-700 dark:text-slate-100 border border-solid border-slate-25 dark:border-slate-800 rounded ">
            {{ a.name }}
          </h1>
          <p class="px-2 mb-0 mt-1 leading-normal text-center text-[12px] text-slate-700 dark:text-slate-100">{{a.description}}</p>
        </router-link>
      </div>
    </div>

    <!-- <button class="bg-red-400 rounded p-2 my-4" @click="listAgents">Listar</button> -->
  </div>
</template>
