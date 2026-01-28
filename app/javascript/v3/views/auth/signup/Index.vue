<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import SignupForm from './components/Signup/Form.vue';
import Testimonials from './components/Testimonials/Index.vue';
import Spinner from 'shared/components/Spinner.vue';
import InfoModal from '../../../../dashboard/components/widgets/modal/InfoModal.vue';

export default {
  components: {
    SignupForm,
    Spinner,
    Testimonials,
    InfoModal
  },
  mixins: [globalConfigMixin],
  data() {
    return {
      isLoading: false,
      showAlert: false,
      error:''
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    isAChatwootInstance() {
      return this.globalConfig.installationName === 'Chatwoot';
    },
  },
  beforeMount() {
    this.isLoading = this.isAChatwootInstance;
  },
  methods: {
    resizeContainers() {
      this.isLoading = false;
    },
    hideAlert() {
      this.showAlert = false
    },
    onAlert(err){
      this.error     = err 
      this.showAlert = true
    }
  },
};
</script>

<template>
  <div class="w-full h-full dark:bg-slate-900">
    <div v-show="!isLoading" class="flex h-full">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-6"
      >
        <div class="px-8 max-w-[560px] w-full overflow-auto">
          <div class="mb-4">
            <h2
              class="mt-6 text-3xl font-medium text-left mb-7 text-slate-900 dark:text-woot-50"
            >
              {{ $t('REGISTER.TRY_WOOT') }}
            </h2>
          </div>
          <SignupForm @alert="onAlert" />
          <div class="px-1 text-sm text-slate-800 dark:text-woot-50">
            <span>{{ $t('REGISTER.HAVE_AN_ACCOUNT') }}</span>
            <router-link class="text-link" to="/app/login">
              {{
                useInstallationName(
                  $t('LOGIN.TITLE'),
                  globalConfig.installationName
                )
              }}
            </router-link>
          </div>
        </div>
      </div>
      <Testimonials
        v-if="isAChatwootInstance"
        class="flex-1"
        @resizeContainers="resizeContainers"
      />
    </div>
    <div
      v-show="isLoading"
      class="flex items-center justify-center w-full h-full"
    >
      <Spinner color-scheme="primary" size="" />
    </div>
    <InfoModal 
      :title="$t('REGISTER.ACCOUNT.LIMIT')"
      :show="showAlert"
      @on-close="hideAlert"
      extra-class="!pt-2" 
    >
      {{ $t('REGISTER.ACCOUNT.MESSAGE') }}
    </InfoModal>
  </div>
</template>

<style>
.text-woot-darker {
  --tw-text-opacity: 1;
  color: rgb(8 110 182 / var(--tw-text-opacity, 1));
}
.text-woot-darker:hover {
  --tw-text-opacity: 0.8;
  color: rgb(8 110 182 / var(--tw-text-opacity, 1));
}
</style>
