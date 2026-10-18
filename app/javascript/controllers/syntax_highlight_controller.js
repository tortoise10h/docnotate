import { Controller } from "@hotwired/stimulus"

// Port of the explain-html style-guide syntax highlighter: a tiny regex
// tokenizer that tints `pre code[class^="language-"]` blocks with the shared
// .tok-* classes. Runs once on connect over the server-rendered node tree.
export default class extends Controller {
  connect() {
    // Mermaid blocks are usually hidden behind their rendered diagram; skip
    // them so the render-error fallback shows plain source.
    this.element.querySelectorAll('pre code[class^="language-"]:not(.language-mermaid)').forEach((el) => {
      const src = el.textContent
      const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      const re = new RegExp([
        "(\\/\\/[^\\n]*|#[^\\n]*|--[^\\n]*)",
        '("(?:[^"\\\\]|\\\\.)*")',
        "\\b(\\d+(?:\\.\\d+)?)\\b",
        "\\b(true|false|null|True|False|None)\\b",
        "\\b(async|await|class|def|do|elif|else|end|except|finally|fn|for|from|function|if|import|in|let|match|module|new|not|or|and|pub|raise|require|return|self|struct|throw|try|type|use|while|with|yield)\\b",
        "([A-Za-z_][\\w-]*)(?=\\()"
      ].join("|"), "g")

      let out = ""
      let last = 0
      let m
      while ((m = re.exec(src)) !== null) {
        if (m[0].length === 0) { re.lastIndex++; continue }
        out += esc(src.slice(last, m.index))
        const cls = m[1] ? "tok-com" : m[2] ? "tok-str" : m[3] ? "tok-num" : m[4] ? "tok-str" : m[5] ? "tok-key" : "tok-fn"
        out += `<span class="${cls}">${esc(m[0])}</span>`
        last = m.index + m[0].length
      }
      out += esc(src.slice(last))
      el.innerHTML = out
    })
  }
}
