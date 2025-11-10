<script>
import wootConstants from 'dashboard/constants/globals';
import Draggable from 'vuedraggable';
import { mapGetters } from 'vuex';
import ColumnItem from './ColumnItem.vue';
import IntersectionObserver from './IntersectionObserver.vue';
import boardConstants from 'dashboard/constants/board';

export default {
  props: {
    column:{
      type: Object,
      required: true
    },
    group: {
      type: String,
      required: true
    },
  },
  components: {
    ColumnItem,
    Draggable,
    IntersectionObserver
  },
  data() {
    return {
      infiniteLoaderOptions: null,
      infiniteLoaderOptions: {
        root: this.$refs.conversationListRef,
        rootMargin: '100px 0px 100px 0px',
      },
      sortByMessage: "last_activity_at_desc"
    }
  },
  computed: {
    ...mapGetters({
      listBoard: 'getBoardConversations',
      boardListLoading: 'getBoardListLoadingStatus',
    }),
    currentFiltersPage() {
      return this.$store.getters['conversationPage/getCurrentPageBoardFilter'](this.column.id);
    },
    hasCurrentPageEndReachedColumn() {
      return this.$store.getters['conversationPage/getHasEndReachedBoard'](this.column.id);
    },
    loading() {
      return this.boardListLoading[`${this.column.id}`] ?? true
    },
    columnDefault() {
      return this.column.order == 0;
    },
    conversationLists() {
      let itemsColumn = this.listBoard.find((column) => column.id == this.column.id)
      return (itemsColumn == undefined ? { id: this.column.id, data: [] } : itemsColumn)
    },
    conversationFilters() {
      let filters = {
        status: "all",
        assignee_type: "all",
        group: this.group,
        page: (this.currentFiltersPage + 1),
        sortBy: this.sortByMessage
      }
      if (!this.columnDefault) {
        filters["group_id"] = this.column.id
      }
      return filters;
    },
    showEndOfListMessage() {
      return (
        this.conversationLists.data.length &&
        this.hasCurrentPageEndReachedColumn &&
        !this.loading
      );
    }
  },
  methods: {
    async add(e) {
      let toColumnState = e.to.__vue__.$parent.column
      let fromList = e.from.__vue__.list
      let toList = e.to.__vue__.list
      let item = e.item._underlying_vm_
      try {
        let payload = {
          params: {
            conversationId: item.id,
            kanban_states_id: (this.columnDefault) ? 'null' : this.column.id,
          },
          kanbanState: boardConstants.mapKanbanState(toColumnState)
        }
        await this.$store.dispatch('fetchUpdateKanbanStateConversation', payload)
        this.$store.dispatch('kanbanState/updateCount', {
          columnIdIncrement: e.to.id,
          columnIdDecrement: e.from.id,
          value: 1,
        })
      } catch (error) {
        fromList.splice(e.oldIndex, 0, item)
        toList.splice(e.newIndex, 1)
      }
    },
    loadMoreConversation() {
      if (this.hasCurrentPageEndReachedColumn || this.loading) {
        return;
      }
      this.$store.dispatch('fetchConversationBoard', { filters: this.conversationFilters, column: this.column })
    },
  },
  mounted() {
    this.$store.dispatch('fetchConversationBoard', { filters: this.conversationFilters, column: this.column })
  }
}
</script>
<template>
  <Draggable 
    ref="conversationListRef" 
    class="flex flex-col gap-1 flex-1 overflow-auto px-2 py-2"
    :list="conversationLists.data" 
    :id="conversationLists.id" 
    group="column" 
    @add="add"
    >
    <ColumnItem v-for="(element) in conversationLists.data" :key="element.id" :source="element" />
    <template>
      <div v-if="loading" class="text-center">
        <span class="mt-4 mb-4 spinner" />
      </div>
      <p v-if="showEndOfListMessage" class="p-4 text-center text-slate-400 dark:text-slate-300">
        {{ $t('CHAT_LIST.EOF') }}
      </p>
      <IntersectionObserver 
        v-if="!showEndOfListMessage" 
        :options="infiniteLoaderOptions"
        @observed="loadMoreConversation" 
      />
    </template>
  </Draggable>
</template>