<script>
import Modal from '../../Modal.vue';

export default {
    components: {
        Modal,
    },
    props: {
        show: {
            type: Boolean,
            default: false,
        },
        title: {
            type: String,
            default: '',
        },
    },
    methods: {
        close() {
            this.$emit('on-close')
        },
    },
};
</script>

<template>
    <woot-modal :show.sync="show" :on-close="close">
        <woot-modal-header :header-title="title" />
        <div class="pt-5 pb-8 px-8">
            <p class="w-full mt-2 text-sm leading-5 break-words text-slate-600 dark:text-slate-300">
                <slot />
            </p>
        </div>
    </woot-modal>
</template>
