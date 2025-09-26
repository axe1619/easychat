<script>
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import draggable from 'vuedraggable';
import ConversationMessageSuggestion from '../ConversationMessageSuggestion.vue';

export default {
  name: 'AIInsightsAccordion',
  components: {
    AccordionItem,
    Draggable: draggable,
    ConversationMessageSuggestion, // para usarlo por nombre de string también
  },
  props: {
    open: { type: Boolean, default: true },
    aiInsightsItems: { type: Array, default: () => [] }, // <- prop fuente de la verdad externa
    dragEnabled: { type: Boolean, default: true },
  },
  data() {
    return {
      dragging: false,
      localItems: [], // <- copia para Draggable (mutación local)
      openState: {},
    };
  },
  mounted() {
    this.syncFromProps();
  },
  watch: {
    aiInsightsItems: {
      handler() {
        this.syncFromProps();
      },
      deep: true,
    },
  },
  methods: {
    syncFromProps() {
      // Copia superficial para poder reordenar sin mutar el prop directamente
      this.localItems = this.aiInsightsItems.map(i => ({ ...i }));
      // Inicializa/actualiza estado de apertura
      const next = {};
      this.localItems.forEach(item => {
        next[item.uiKey] = false;
      });
      this.openState = { ...this.openState, ...next };
    },
    onDragEnd() {
      this.dragging = false;
      // Emite el nuevo orden completo (puedes cambiar el evento si prefieres v-model)
      this.$emit('reorder', this.localItems);
      // O solo los names:
      this.$emit(
        'update:order',
        this.localItems.map(i => i.name)
      );
    },
    toggleOpen(uiKey) {
      this.openState = { ...this.openState, [uiKey]: !this.openState[uiKey] };
    },
    isOpen(uiKey) {
      return !!this.openState[uiKey];
    },
  },
};
</script>

<template>
  <div
    v-if="open"
    class="ia-insights-accordion"
  >
    <Draggable
      :list="localItems"
      :disabled="!dragEnabled"
      class="list-group"
      ghost-class="ghost"
      @start="dragging = true"
      @end="onDragEnd"
      item-key="name"
    >
      <transition-group type="transition" name="fade">
        <div
          v-for="element in localItems"
          :key="element.name"
          class="list-group-item"
        >
          <AccordionItem
            :title="element.title"
            :is-open="isOpen(element.uiKey)"
            compact
            @click="() => toggleOpen(element.uiKey)"
          >
            <!-- 1) Si viene como componente dinámico + props -->
            <component
              v-if="element.contentComponent"
              :is="element.contentComponent"
              v-bind="element.contentProps"
            />
            <!-- 2) Si viene como texto -->
            <div v-else class="p-4">
              {{ element.content }}
            </div>
          </AccordionItem>
        </div>
      </transition-group>
    </Draggable>
  </div>
</template>

<style lang="scss" scoped>
.list-group {
  .list-group-item {
    @apply bg-white dark:bg-slate-900;
  }
}
.ghost {
  opacity: 0.6;
  @apply ring-2 ring-indigo-500/40;
}
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
.ia-insights-accordion {
  width: 350px;
  overflow-y: auto;
}
</style>
