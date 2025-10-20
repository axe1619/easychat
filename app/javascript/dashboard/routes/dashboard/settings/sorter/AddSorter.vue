<script>
import { mapGetters } from 'vuex';
import staticValidations, { getSorterTitleErrorMessage, getSorterDescriptionErrorMessage } from './validations';
import { getRandomColor } from 'dashboard/helper/labelColor';
import { useVuelidate } from '@vuelidate/core';
import { minLength, requiredIf } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { getInboxSource } from 'dashboard/helper/inbox';
import SwitchButton from "dashboard/components/ui/Switch.vue";
import InboxDropdownItem from 'dashboard/components/widgets/InboxDropdownItem.vue';
export default {
  components: {
    SwitchButton,
    InboxDropdownItem
  },
  props: {
    prefillTitle: {
      type: String,
      default: '',
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      color: '#000',
      description: '',
      name: '',
      enabledNotification: false,
      notify: [],
      options: [],
      selectedInbox: undefined
    };
  },
  validations() {
    return {
      ...staticValidations,
      notify: {
        required: requiredIf(() => this.enabledNotification),
        minLength: function () {
          if (!this.enabledNotification) return minLength(0)
          return minLength(1)
        }
      },
      selectedInbox: {
        required: requiredIf(() => this.enabledNotification),
      }
    }
  },
  computed: {
    ...mapGetters({
      uiFlags: 'sorter/getUIFlags',
      currentUser: 'getCurrentUser',
      notificationInboxes: 'inboxes/getNotificationInboxes',
    }),
    sorterTitleErrorMessage() {
      const errorMessage = getSorterTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
    sorterDescriptionErrorMessage() {
      const errorMessage = getSorterDescriptionErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
    disableButtonCreate() {
      return this.v$.name.$invalid || this.v$.description.$invalid || this.v$.notify.$invalid || this.v$.selectedInbox.$invalid || this.uiFlags.isCreating
    },
  },
  mounted() {
    this.color = getRandomColor();
    this.name = this.prefillTitle.toLowerCase();
    this.description = '';
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addSorter() {
      try {
        let sorter = {
          color: this.color,
          description: this.description,
          name: this.name.toLowerCase()
        }
        if (this.enabledNotification) {
          sorter.notification = {
            sender_id: this.currentUser.id,
            phones: this.notify.map((value) => value.name),
            inbox_id: this.selectedInbox.id
          }
        }
        await this.$store.dispatch('sorter/create', sorter);
        useAlert(this.$t('SORTER.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage = error.message || this.$t('SORTER.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
    computedInboxSource(inbox) {
      if (!inbox.channel_type) return '';
      const classByType = getInboxSource(
        inbox.channel_type,
        inbox.phone_number,
        inbox
      );
      return classByType;
    },
    onSwitchNotification() {
      this.enabledNotification = !this.enabledNotification
    },
    addNotify(value) {
      this.notify.push({ name: value })
      this.options.push({ name: value })
    }
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="$t('SORTER.ADD.TITLE')" :header-content="$t('SORTER.ADD.DESC')" />
    <form class="flex flex-wrap mx-0" @submit.prevent="addSorter">
      <woot-input v-model.trim="name" :class="{ error: v$.name.$error }" class="w-full label-name--input"
        :label="$t('SORTER.FORM.NAME.LABEL')" :placeholder="$t('SORTER.FORM.NAME.PLACEHOLDER')"
        :error="sorterTitleErrorMessage" data-testid="label-title" @input="v$.name.$touch" />

      <woot-text-area v-model.trim="description" :class="{ error: v$.description.$error }" class="w-full"
        :label="$t('SORTER.FORM.DESCRIPTION.LABEL')" :placeholder="$t('SORTER.FORM.DESCRIPTION.PLACEHOLDER')"
        data-testid="label-description" @input="v$.description.$touch" :error="sorterDescriptionErrorMessage" />

      <div class="flex items-center justify-between w-full">
        <label>
          {{ $t('SORTER.FORM.COLOR.LABEL') }}
          <woot-color-picker v-model="color" />
        </label>
        <label class="flex flex-col gap-2 mb-4 items-end">
          <span>{{ $t('SORTER.NOTIFICATION.ENABLED') }}</span>
          <SwitchButton 
            :value="enabledNotification"
            @input="onSwitchNotification"
          />
        </label>
      </div>

      <div v-if="enabledNotification" class="w-full">
        <label>{{ $t('SORTER.NOTIFICATION.SEND') }}:</label>
        <multiselect
          v-model="selectedInbox"
          track-by="id"
          label="name"
          :placeholder="$t('FORMS.MULTISELECT.SELECT')"
          :max-height="140"
          close-on-select
          :options="notificationInboxes"
        >
          <template slot="singleLabel" slot-scope="{ option }">
            <InboxDropdownItem
              v-if="option.name"
              :name="option.name"
              :inbox-identifier="computedInboxSource(option)"
              :channel-type="option.channel_type"
            />
            <span v-else>
              {{ $t('NEW_CONVERSATION.FORM.INBOX.PLACEHOLDER') }}
            </span>
          </template>
          <template slot="option" slot-scope="{ option }">
            <InboxDropdownItem
              :name="option.name"
              :inbox-identifier="computedInboxSource(option)"
              :channel-type="option.channel_type"
            />
          </template>
        </multiselect>
        <label>{{ $t('SORTER.NOTIFICATION.NOTIFIED') }}:</label>
        <multiselect
          track-by="name"
          label="name"
          v-model="notify"
          :options="options"
          multiple
          taggable
          @tag="addNotify"
        />
      </div>
      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <woot-button :is-disabled="disableButtonCreate"
          :is-loading="uiFlags.isCreating" data-testid="label-submit">
          {{ $t('SORTER.FORM.CREATE') }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('SORTER.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
// Label API supports only lowercase letters
.label-name--input {
  ::v-deep {
    input {
      @apply lowercase;
    }
  }
}
</style>
