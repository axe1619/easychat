<script>
import { VeTable } from 'vue-easytable';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { frontendURL } from 'dashboard/helper/URLHelper';
import EmptyState from '../../../components/widgets/EmptyState.vue';
import Spinner from '../../../../shared/components/Spinner.vue';
export default {
  components: {
    VeTable,
    EmptyState,
    Spinner,
  },
  props: {
    messages: {
      type: Array,
      default: () => [],
    },
    accountId: {
      type: Number,
      required: true
    },
    isLoading: {
      type: Boolean,
      required: true
    }
  },
  computed: {
    tableData() {
      return this.messages.map(item => {
        const { created_at: createdAt } = item;
        return {
          ...item,
          created_at: createdAt ? dynamicTime(Date.parse(createdAt) / 1000) : '---',
        };
      });
    },
    columns() {
      return [
        {
          field: 'contact_name',
          key: 'contact_name',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.NAME'),
          renderBodyCell: ({ row }) => (
            <woot-button
              variant="clear"
              onClick={() => this.viewMessage(row.conversation_display_id, row.id)}
            >
              <div class="row--user-block">
                <div class="user-block">
                  <h6 class="overflow-hidden text-base whitespace-nowrap text-ellipsis">
                    <small>
                      {row.contact_name}
                    </small>
                  </h6>
                  <button class="button clear small link view-details--button">
                    {this.$t('CONTACTS_PAGE.LIST.VIEW_MESSAGE')}
                  </button>
                </div>
              </div>
            </woot-button>
          )
        },
        {
          field: 'contact_phone_number',
          key: 'contact_phone_number',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.PHONE_NUMBER'),
        },
        {
          field: 'created_at',
          key: 'created_at',
          title: this.$t('CONTACTS_PAGE.LIST.TABLE_HEADER.CREATED_AT'),
        },
      ];
    },
  },
  methods: {
    viewMessage(conversation_display_id, messageId) {
      this.$router.push({ path: frontendURL(`accounts/${this.accountId}/conversations/${conversation_display_id}?messageId=${messageId}`) })
    }
  }
};
</script>

<template>
  <section class="">
    <VeTable 
      :columns="columns"
      :table-data="tableData" 
    />
    <EmptyState
      v-if="!isLoading && !messages.length"
      :title="$t('CONTACTS_PAGE.LIST.MESSAGE.NO_MESSAGES')"
    />
    <div v-if="isLoading" class="flex items-center justify-center text-base">
      <Spinner color-scheme="primary" size="small" />
      <span>{{ $t('CONTACTS_PAGE.LIST.MESSAGE.LOADING') }}</span>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.conversations-table-wrap::v-deep {
  .ve-table {
    @apply pb-8;
  }

  .row--user-block {
    @apply items-center flex text-left;

    .user-block {
      @apply items-start flex flex-col my-0 mx-2;
    }

    .user-name {
      @apply text-sm font-medium m-0 capitalize;
    }

    .view-details--button {
      @apply text-slate-600 dark:text-slate-200;
    }

    .user-email {
      @apply m-0;
    }
  }

  .ve-table-header-th {
    padding: var(--space-small) var(--space-two) !important;
  }

  .ve-table-body-td {
    padding: var(--space-small) var(--space-two) !important;
  }

  .ve-table-header-th {
    font-size: var(--font-size-mini) !important;
  }

  .ve-table-sort {
    @apply -top-1;
  }
}

.cell--social-profiles {
  a {
    @apply text-slate-300 dark:text-slate-400 text-lg min-w-[2rem] text-center;
  }
}
</style>
