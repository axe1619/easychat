<template>
  <div>
    <textarea ref="ta"></textarea>
  </div>
</template>

<script>
export default {
  name: 'TinyEditor',
  props: {
    value: { type: String, default: '' },        // Vue 2
    modelValue: { type: String, default: '' },   // Vue 3
    height: { type: Number, default: 420 },
    menubar: { type: [Boolean, String], default: false },
    toolbar: {
      type: String,
      default:
        'undo redo | bold italic underline | bullist numlist | link | fullscreen | code'
    },
    plugins: { type: String, default: 'searchreplace fullscreen' }, //code lists link
  },

  data() {
    return {
      editor: null,
      isDark: false,
    }
  },

  computed: {
    innerValue() {
      return this.modelValue !== '' ? this.modelValue : this.value
    },
  },

  methods: {
    detectTheme() {
      const styleAttr = document.documentElement.getAttribute('style') || ''
      this.isDark = styleAttr.includes('dark')
    },

    buildContentStyle() {
      const fg   = this.isDark ? '#f1f5f9' : '#26292B'   // texto
      const bg   = this.isDark ? '#26292B' : '#ffffff'   // fondo
      const bd   = this.isDark ? '#475569' : '#e2e8f0'   // bordes (tablas, etc)
      const link = this.isDark ? '#60a5fa' : '#2563eb'   // links

      return `
        :root { --te-fg:${fg}; --te-bg:${bg}; --te-bd:${bd}; --te-link:${link}; }
        html, body { height: 100%; }
        body {
          margin: 0;
          padding: 0.75rem;
          font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif;
          line-height: 1.5;
          font-size: 0.875rem;
          color: var(--te-fg);
          background-color: var(--te-bg);
          border: none;         /* sin borde */
          border-radius: 0;     /* sin radios */
          box-shadow: none;     /* sin sombra interior */
          box-sizing: border-box;
        }
        p { margin: 0 0 0.5rem; }
        a { color: var(--te-link); text-decoration: underline; }
        ul,ol { padding-left: 1.25rem; margin: 0.5rem 0; }
        code { background: #f1f5f9; padding: 0.1rem 0.3rem; border-radius: 4px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid var(--te-bd); padding: 0.375rem 0.5rem; }
      `
    },
    injectContentStyle() {
      if (!this.editor || !this.editor.initialized) return
      const head = this.editor.getDoc().head
      const prev = head.querySelector('style[data-te-style]')
      if (prev) prev.remove()
      const styleEl = this.editor.getDoc().createElement('style')
      styleEl.setAttribute('data-te-style', 'true')
      styleEl.type = 'text/css'
      styleEl.appendChild(this.editor.getDoc().createTextNode(this.buildContentStyle()))
      head.appendChild(styleEl)
    },
    applyThemeToEditor() {
      this.injectContentStyle()
    },
    initEditor() {
      const baseUrl = '/assets/tinymce'
      const start = () => {
        window.tinymce.init({
          target: this.$refs.ta,
          base_url: baseUrl,
          suffix: '.min',
          height: this.height,
          menubar: this.menubar,
          toolbar: this.toolbar,
          plugins: this.plugins,
          branding: false,
          statusbar: false,
          browser_spellcheck: true,
          skin_url: `${baseUrl}/skins/ui/oxide`,
          content_css: `${baseUrl}/skins/content/default/content.min.css`,

          content_style: this.buildContentStyle(),

          setup: (ed) => {
            this.editor = ed

            ed.on('init', () => {
              ed.setContent(this.innerValue || '')
              this.injectContentStyle()
            })

            const emit = () => {
              const html = ed.getContent()
              this.$emit('input', html)                 // Vue 2
              this.$emit('update:modelValue', html)     // Vue 3
            }
            ed.on('change keyup undo redo input SetContent', emit)
          },
        })
      }

      if (window.tinymce) start()
      else {
        const s = document.createElement('script')
        s.src = `${baseUrl}/tinymce.min.js`
        s.onload = start
        document.head.appendChild(s)
      }
    },
  },

  watch: {
    innerValue(newVal) {
      if (this.editor && this.editor.initialized) {
        const current = this.editor.getContent()
        if (newVal !== current) this.editor.setContent(newVal || '')
      }
    },
    isDark() {
      this.applyThemeToEditor()
    },
  },

  mounted() {
    this.detectTheme()
    this.initEditor()
  },

  beforeDestroy() { if (this.editor) this.editor.remove() },
  unmounted() { if (this.editor) this.editor.remove() },
}
</script>

<style scoped>
:deep(.tox) {
  border-radius: 0.5rem;
}
:deep(.tox .tox-toolbar__primary) {
  padding: 4px 6px;
}
</style>
