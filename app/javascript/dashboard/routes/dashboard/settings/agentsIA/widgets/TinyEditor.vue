<!-- <script>
// import '../../../../../../../assets/javascripts/tinymce/tinymce.min.js';
export default {
  name: 'TinyEditor',
  props: {
    modelValue: { type: String, default: '' }, // para v-model
    height: { type: Number, default: 320 },
  },
  mounted() {
    // ruta base donde están tinymce.min.js, skins, plugins, etc.
    const baseUrl = '../../../../../../../assets/javascripts/tinymce' // ajusta: /assets/tinymce, /packs/tinymce, etc.

    // Espera a que window.tinymce exista si se carga async
    const start = () => {
      window.tinymce?.init({
        target: this.$refs.editor,
        base_url: baseUrl,        // importante para que encuentre plugins/skins
        suffix: '.min',           // si tus archivos son *.min.js
        skin_url: `${baseUrl}/skins/ui/oxide`,        // opcional si no detecta
        content_css: `${baseUrl}/skins/content/default/content.min.css`,
        height: this.height,
        menubar: 'file edit view insert format tools table',
        toolbar:
          'undo redo | bold italic underline | bullist numlist | link image | searchreplace fullscreen | code',
        plugins: 'searchreplace fullscreen code lists link',
        statusbar: false,
        branding: false,
        browser_spellcheck: true,
        // Idioma (si tienes el paquete de idioma)
        // language: 'es',
        // language_url: `${baseUrl}/langs/es.js`, // si existe en tu bundle

        setup: (editor) => {
          editor.on('init', () => {
            editor.setContent(this.modelValue || '')
          })
          editor.on('change keyup undo redo', () => {
            this.$emit('update:modelValue', editor.getContent())
          })
        },
      })
    }

    if (window.tinymce) start()
    else {
      // si fuese necesario esperar unas ms…
      const timer = setInterval(() => {
        if (window.tinymce) {
          clearInterval(timer)
          start()
        }
      }, 50)
    }
  },
  beforeDestroy() {
    const ed = window.tinymce?.get(this.$refs.editor?.id)
    ed && ed.remove()
  },
}
</script>

<template>
  <div>
    <textarea ref="editor"></textarea>
  </div>
</template> -->
