<script>
import { useAdmin } from 'dashboard/composables/useAdmin';
import BackButton from '../../../components/widgets/BackButton.vue';
import InfoModal from '../../../components/widgets/modal/InfoModal.vue';

export default {
  components: {
    BackButton,
    InfoModal
  },
  props: {
    headerTitle: {
      default: '',
      type: String,
    },
    buttonRoute: {
      default: '',
      type: String,
    },
    buttonText: {
      default: '',
      type: String,
    },
    icon: {
      default: '',
      type: String,
    },
    showBackButton: { type: Boolean, default: false },
    showNewButton: { type: Boolean, default: false },
    backUrl: {
      type: [String, Object],
      default: '',
    },
    backButtonLabel: {
      type: String,
      default: '',
    },
    showSidemenuIcon: {
      type: Boolean,
      default: true,
    },
    verifyLimitResource: {
      type: Function,
      default: null
    }
  },
  data() {
    return {
      exceededLimit: true,
      messageLimit: '',
      showAlertLimit: false
    }
  },
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  computed: {
    iconClass() {
      return `icon ${this.icon} header--icon`;
    },
  },
  methods: {
    async limitResource() {
      if (!this.verifyLimitResource) return
      const { exceededLimitResource , resource } = await this.verifyLimitResource()
      if (!exceededLimitResource) {
        this.exceededLimit = false
        return
      }
      this.exceededLimit = true
      this.messageLimit  = resource
    },
    async goRoute(){
      await this.limitResource()
      if(this.exceededLimit){
        this.showAlertLimit = true
        return
      }
      this.$router.push(this.buttonRoute)
    },
    hideAlertLimit(){
      this.showAlertLimit = false
    }
  }
};
</script>

<template>
  <div
    class="flex justify-between items-center h-14 min-h-[3.5rem] px-4 py-2 bg-white dark:bg-slate-900 border-b border-slate-50 dark:border-slate-800/50"
  >
    <InfoModal 
      :title="$t(`${messageLimit}.PAYMENT.TITLE`)"
      :show="showAlertLimit"
      @on-close="hideAlertLimit" 
    >
      {{ $t(`${messageLimit}.PAYMENT.MESSAGE`) }}
      <a target="_blank" :href="$t('INBOX.PAYMENT.REFERENCE.REDIRECT')">
        {{ $t(`${messageLimit}.PAYMENT.REFERENCE.TITLE`) }}
      </a>
    </InfoModal>
    <h1
      class="flex items-center mb-0 text-2xl text-slate-900 dark:text-slate-100"
    >
      <woot-sidemenu-icon v-if="showSidemenuIcon" />
      <BackButton
        v-if="showBackButton"
        :button-label="backButtonLabel"
        :back-url="backUrl"
        class="ml-2 mr-4"
      />
      <fluent-icon
        v-if="icon"
        :icon="icon"
        :class="iconClass"
        class="hidden ml-1 mr-2 rtl:ml-2 rtl:mr-1 md:block"
      />
      <slot />
      <span class="text-2xl font-medium text-slate-900 dark:text-slate-100">
        {{ headerTitle }}
      </span>
    </h1>
    <woot-button
      v-if="showNewButton && isAdmin"
      color-scheme="success"
      class="button success button--fixed-top px-3.5 py-1 rounded-[5px] flex gap-2"
      @click="goRoute"
    >
      <fluent-icon icon="add-circle" />
      <span class="button__content">
        {{ buttonText }}
      </span>
    </woot-button>
  </div>
</template>
