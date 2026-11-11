// overtype@2.7.0 downloaded from https://ga.jspm.io/npm:overtype@2.7.0/dist/overtype.esm.js

/**
* OverType v2.7.0
* A lightweight markdown editor library with perfect WYSIWYG alignment
* @license MIT
* @author David Miranda
* https://github.com/panphora/overtype
*/
var e=Object.defineProperty,t=(t,n,r)=>n in t?e(t,n,{enumerable:!0,configurable:!0,writable:!0,value:r}):t[n]=r,n=(t,n)=>{for(var r in n)e(t,r,{get:n[r],enumerable:!0})},r=(e,n,r)=>(t(e,typeof n==`symbol`?n:n+``,r),r);function i(e){var t,n;let r=/^( {0,3})(#{1,6})(?:([\t ]+)(.*)|$)/.exec(e);if(!r||r[2].length>3)return null;let i=r[1],a=r[2],o=(t=r[3])==null?``:t,s=(n=r[4])==null?``:n,c=/^(#+)[\t ]*$/.exec(s),l=/([\t ]+)(#+)([\t ]*)$/.exec(s),u=c||l;return{type:`heading`,level:a.length,indent:i,marker:a,separator:o,content:c?``:u?s.slice(0,l.index):s,closing:c?s:u?l[0]:``}}function a(e){let t=/^( {0,3})([*_-])([\t *_-]*)$/.exec(e);if(!t)return null;let n=t[2],r=t[3];return[...r].some(e=>e!==n&&e!==` `&&e!==`	`)||1+[...r].filter(e=>e===n).length<3?null:{type:`thematic-break`,marker:n,source:e}}function o(e){let t=/^( {0,3})>([\t ]?)(.*)$/.exec(e);return!t||t[2]===``&&t[3].startsWith(`>`)?null:{type:`blockquote`,indent:t[1],marker:`>`,separator:t[2],content:t[3]}}function s(e){let t=/^( *)([-*+])([\t ]+)(.*)$/.exec(e);if(t)return{type:`list-item`,listType:`bullet`,indent:t[1],marker:t[2],separator:t[3],content:t[4]};let n=/^( *)([-*+])$/.exec(e);if(n)return{type:`list-item`,listType:`bullet`,indent:n[1],marker:n[2],separator:``,content:``};let r=/^( *)(\d{1,9}\.)([\t ]+)(.*)$/.exec(e);if(r)return{type:`list-item`,listType:`ordered`,indent:r[1],marker:r[2],separator:r[3],content:r[4]};let i=/^( *)(\d{1,9}\.)$/.exec(e);return i?{type:`list-item`,listType:`ordered`,indent:i[1],marker:i[2],separator:``,content:``}:null}function c(e){let t=/^( {0,3})(`{3,})([^`]*)$/.exec(e);return t?{type:`fence-open`,indent:t[1],marker:t[2],length:t[2].length,info:t[3].trim(),source:e}:null}function l(e,t){let n=/^( {0,3})(`{3,})[\t ]*$/.exec(e);return!n||n[2].length<t.length?null:{type:`fence-close`,indent:n[1],marker:n[2],length:n[2].length,source:e}}var u=/[!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~]/,d=/^&(?:amp|lt|gt|quot|#39);/,f={"&amp;":`&`,"&lt;":`<`,"&gt;":`>`,"&quot;":`"`,"&#39;":`'`};function p(e,t){return function n(r){if(r>=e.length)return[null,0];if(t&&e.charCodeAt(r)===38){let t=d.exec(e.slice(r,r+6));if(t)return[f[t[0]],t[0].length]}return[e[r],1]}}function m(e,t){let n=0;for(;t>0&&e[--t]===`\\`;)n++;return n%2==1}var h=e=>e===` `||e===`	`,g=e=>e!==null&&(e.charCodeAt(0)<32||e.charCodeAt(0)===127);function _(e,t,n,r){let[i,a]=n(t);if(i!==`(`)return null;for(t+=a;h(i=n(t)[0]);)t+=n(t)[1];let o=null;if([i,a]=n(t),i===`<`){let r=t,s=``;for(t+=a;;){if([i,a]=n(t),i===null||i===`<`||i===`
`)return null;if(i===`\\`){let[e,r]=n(t+a);if(e!==null&&u.test(e)){s+=e,t+=a+r;continue}}if(i===`>`){t+=a;break}s+=i,t+=a}o={start:r,end:t,raw:e.slice(r,t),value:s}}else if(i!==`)`){let s=t,c=0,l=``;for(;[i,a]=n(t),!(i===null||i===`
`||h(i));){if(g(i))return null;if(i===`\\`){let[e,r]=n(t+a);if(e!==null&&u.test(e)){l+=e,t+=a+r;continue}l+=i,t+=a;continue}if(i===`(`){if(c++,c>r)return null;l+=i,t+=a;continue}if(i===`)`){if(c===0)break;c--,l+=i,t+=a;continue}l+=i,t+=a}if(c!==0)return null;o={start:s,end:t,raw:e.slice(s,t),value:l}}let s=t;for(;h(i=n(t)[0]);)t+=n(t)[1];let c=null;if([i,a]=n(t),i===`"`||i===`'`||i===`(`){if(o&&t===s)return null;let r=i===`(`?`)`:i,l=t,d=``;for(t+=a;;){if([i,a]=n(t),i===null||i===`
`)return null;if(i===`\\`){let[e,r]=n(t+a);if(e!==null&&u.test(e)){d+=e,t+=a+r;continue}d+=i,t+=a;continue}if(i===r){t+=a;break}if(r===`)`&&i===`(`)return null;d+=i,t+=a}for(c={start:l,end:t,raw:e.slice(l,t),value:d,delimiter:r===`)`?`(`:r};h(i=n(t)[0]);)t+=n(t)[1]}return[i,a]=n(t),i===`)`?{end:t+a,destination:o,title:c}:null}function v(e,t,n){for(;n<e.length&&e[n].end<=t;)n++;let r=e[n];return{range:r&&r.start<=t&&t<r.end?r:null,rangeIndex:n}}function y(e,{htmlEntities:t=!1,maxParenDepth:n=32,ignoreRanges:r=[]}={}){let i=p(e,t),a=[...r].sort((e,t)=>e.start-t.start),o=[],s=[],c=0,l=0;for(;l<e.length;){let t=v(a,l,c);if(c=t.rangeIndex,t.range){l=t.range.end;continue}let[r,d]=i(l);if(r===`\\`){let[e,t]=i(l+d);l+=e!==null&&u.test(e)?d+t:d;continue}if(r===`
`){s.length=0,l+=d;continue}if(r===`[`){let t=l>0&&e[l-1]===`!`&&!m(e,l-1);s.push({index:l,image:t}),l+=d;continue}if(r===`]`){let t=s.pop();if(t){let r=_(e,l+d,i,n);if(r){o.push({start:t.index,end:r.end,image:t.image,text:{start:t.index+1,end:l,raw:e.slice(t.index+1,l)},destination:r.destination,title:r.title}),s.length=0,l=r.end;continue}}}l+=d}return o}function b(e,t=[]){let n=[],r=[],i=0;for(;i<e.length;){if(e[i]!=="`"){i++;continue}let t=i;for(;e[i]==="`";)i++;n.push({start:t,end:i,length:i-t})}let a=Array(n.length),o=/* @__PURE__ */ new Map;for(let e=n.length-1;e>=0;e--){let t=n[e];a[e]=o.get(t.length),o.set(t.length,e)}for(let i=0;i<n.length;){let o=n[i],s=m(e,o.start)||t.some(e=>o.start>=e.start&&o.start<e.end),c=a[i];if(s||c===void 0){i++;continue}let l=n[c];r.push({start:o.start,end:l.end,raw:e.slice(o.start,l.end),openTicks:e.slice(o.start,o.end),content:e.slice(o.end,l.start),closeTicks:e.slice(l.start,l.end)}),i=c+1}return r}function ee(e,t){return{...e,start:e.start+t,end:e.end+t,text:{...e.text,start:e.text.start+t,end:e.text.end+t},destination:e.destination&&{...e.destination,start:e.destination.start+t,end:e.destination.end+t},title:e.title&&{...e.title,start:e.title.start+t,end:e.title.end+t}}}function te(e,t){if(!e.includes(`[`))return[];let n=y(e,t),r=/* @__PURE__ */ new Set;for(;;){let i=n.map(e=>`${e.start}:${e.end}`).join(`,`);if(r.has(i))return n;r.add(i);let a=b(e,n.map(e=>({start:e.text.end,end:e.end}))),o=y(e,{...t,ignoreRanges:a});if(o.map(e=>`${e.start}:${e.end}`).join(`,`)===i)return o;n=o}}function ne(e,t={}){let{fences:n=!0,...r}=t,i=[],a=e.split(`
`),o=null,s=0;for(let e of a){if(o)l(e,o)&&(o=null);else{let t=n&&c(e);t?o=t:i.push(...te(e,r).map(e=>ee(e,s)))}s+=e.length+1}return i}var re={"&amp;":`&`,"&lt;":`<`,"&gt;":`>`,"&quot;":`"`,"&#39;":`'`},ie=/^&(amp|lt|gt|quot|#39);/,x=/^[!"#$%&'()*+,\-./:;<=>?@[\]\\^_`{|}~]$/,ae=/^[\u00a1-\u00a9\u00ab-\u00ac\u00ae-\u00b1\u00b4\u00b6-\u00b8\u00bb\u00bf\u00d7\u00f7\u02c2-\u02c5\u02d2-\u02df\u02e5-\u02eb\u02ed\u02ef-\u02ff\u0375\u037e\u0384-\u0385\u0387\u03f6\u0482\u055a-\u055f\u0589-\u058a\u058d-\u058f\u05be\u05c0\u05c3\u05c6\u05f3-\u05f4\u0606-\u060f\u061b\u061d-\u061f\u066a-\u066d\u06d4\u06de\u06e9\u06fd-\u06fe\u0700-\u070d\u07f6-\u07f9\u07fe-\u07ff\u0830-\u083e\u085e\u0888\u0964-\u0965\u0970\u09f2-\u09f3\u09fa-\u09fb\u09fd\u0a76\u0af0-\u0af1\u0b70\u0bf3-\u0bfa\u0c77\u0c7f\u0c84\u0d4f\u0d79\u0df4\u0e3f\u0e4f\u0e5a-\u0e5b\u0f01-\u0f17\u0f1a-\u0f1f\u0f34\u0f36\u0f38\u0f3a-\u0f3d\u0f85\u0fbe-\u0fc5\u0fc7-\u0fcc\u0fce-\u0fda\u104a-\u104f\u109e-\u109f\u10fb\u1360-\u1368\u1390-\u1399\u1400\u166d-\u166e\u169b-\u169c\u16eb-\u16ed\u1735-\u1736\u17d4-\u17d6\u17d8-\u17db\u1800-\u180a\u1940\u1944-\u1945\u19de-\u19ff\u1a1e-\u1a1f\u1aa0-\u1aa6\u1aa8-\u1aad\u1b4e-\u1b4f\u1b5a-\u1b6a\u1b74-\u1b7f\u1bfc-\u1bff\u1c3b-\u1c3f\u1c7e-\u1c7f\u1cc0-\u1cc7\u1cd3\u1fbd\u1fbf-\u1fc1\u1fcd-\u1fcf\u1fdd-\u1fdf\u1fed-\u1fef\u1ffd-\u1ffe\u2010-\u2027\u2030-\u205e\u207a-\u207e\u208a-\u208e\u20a0-\u20c0\u2100-\u2101\u2103-\u2106\u2108-\u2109\u2114\u2116-\u2118\u211e-\u2123\u2125\u2127\u2129\u212e\u213a-\u213b\u2140-\u2144\u214a-\u214d\u214f\u218a-\u218b\u2190-\u2429\u2440-\u244a\u249c-\u24e9\u2500-\u2775\u2794-\u2b73\u2b76-\u2b95\u2b97-\u2bff\u2ce5-\u2cea\u2cf9-\u2cfc\u2cfe-\u2cff\u2d70\u2e00-\u2e2e\u2e30-\u2e5d\u2e80-\u2e99\u2e9b-\u2ef3\u2f00-\u2fd5\u2ff0-\u2fff\u3001-\u3004\u3008-\u3020\u3030\u3036-\u3037\u303d-\u303f\u309b-\u309c\u30a0\u30fb\u3190-\u3191\u3196-\u319f\u31c0-\u31e5\u31ef\u3200-\u321e\u322a-\u3247\u3250\u3260-\u327f\u328a-\u32b0\u32c0-\u33ff\u4dc0-\u4dff\ua490-\ua4c6\ua4fe-\ua4ff\ua60d-\ua60f\ua673\ua67e\ua6f2-\ua6f7\ua700-\ua716\ua720-\ua721\ua789-\ua78a\ua828-\ua82b\ua836-\ua839\ua874-\ua877\ua8ce-\ua8cf\ua8f8-\ua8fa\ua8fc\ua92e-\ua92f\ua95f\ua9c1-\ua9cd\ua9de-\ua9df\uaa5c-\uaa5f\uaa77-\uaa79\uaade-\uaadf\uaaf0-\uaaf1\uab5b\uab6a-\uab6b\uabeb\ufb29\ufbb2-\ufbc2\ufd3e-\ufd4f\ufdcf\ufdfc-\ufdff\ufe10-\ufe19\ufe30-\ufe52\ufe54-\ufe66\ufe68-\ufe6b\uff01-\uff0f\uff1a-\uff20\uff3b-\uff40\uff5b-\uff65\uffe0-\uffe6\uffe8-\uffee\ufffc-\ufffd]$/,oe=/^\uE000\d+\uE001/;function se(){try{return/* @__PURE__ */ RegExp(`^[\\p{P}\\p{S}]$`,`u`)}catch(e){return ae}}var ce=se();function le(e){return e!==null&&(x.test(e)||ce.test(e))}function ue(e,t,n){if(t>=e.length)return[null,0];if(e[t]===``){let n=oe.exec(e.slice(t));if(n)return["`",n[0].length]}if(n&&e[t]===`&`){let n=ie.exec(e.slice(t,t+6));if(n)return[re[n[0]],n[0].length]}let r=String.fromCodePoint(e.codePointAt(t));return[r,r.length]}function de(e,t){let n=0;for(;t>0&&e[--t]===`\\`;)n++;return n%2==1}function fe(e,t){if(e[t]!==`<`)return t;let n=e.indexOf(`>`,t+1);return n===-1?t:n+1}function pe(e,t,n){let r=t;for(;r<e.length;){let t=fe(e,r);if(t!==r){r=t;continue}return ue(e,r,n)[0]}return`
`}function me(e,t,n){let r=/\s/u.test(t),i=/\s/u.test(n),a=le(t),o=le(n),s=!i&&(!o||r||a),c=!r&&(!a||i||o);return e===`_`?{canOpen:s&&(!c||a),canClose:c&&(!s||o)}:{canOpen:s,canClose:c}}function he(e,t){let n=[],r=`
`,i=0;for(;i<e.length;){let a=fe(e,i);if(a!==i){i=a;continue}let[o,s]=ue(e,i,t);if((o===`*`||o===`_`)&&!de(e,i)){let a=i,s=0;for(;e[i]===o&&!de(e,i);)s++,i++;let c=me(o,r,pe(e,i,t)),l={marker:o,start:a,original:s,remaining:s,usedAsOpener:0,usedAsCloser:0,...c,previous:n.length>0?n[n.length-1]:null,next:null};l.previous&&(l.previous.next=l),n.push(l),r=o;continue}r=o,i+=s}return n}function ge(e,t){t.previous?t.previous.next=t.next:e.head=t.next,t.next&&(t.next.previous=t.previous),t.previous=null,t.next=null}function _e(e,t){let n=e.next;for(;n&&n!==t;){let e=n.next;n.previous=null,n.next=null,n=e}e.next=t,t.previous=e}function ve(e,{htmlEntities:t=!1}={}){var n;let r={head:(n=he(e,t)[0])==null?null:n},i=[],a=r.head;for(;a;){if(!a.canClose){a=a.next;continue}let e=a.previous;for(;e;){let t=(a.canOpen||e.canClose)&&(e.original%3!=0||a.original%3!=0)&&(e.original+a.original)%3==0;if(e.marker===a.marker&&e.canOpen&&!t)break;e=e.previous}if(!e){let e=a.next;a.canOpen||ge(r,a),a=e;continue}let t=e.remaining>=2&&a.remaining>=2?2:1,n=e.start+e.original-e.usedAsOpener-t,o=a.start+a.usedAsCloser;i.push({type:t===2?`strong`:`em`,openStart:n,openEnd:n+t,closeStart:o,closeEnd:o+t}),e.remaining-=t,a.remaining-=t,e.usedAsOpener+=t,a.usedAsCloser+=t,_e(e,a);let s=a.next;e.remaining===0&&ge(r,e),a.remaining===0&&(ge(r,a),a=s)}return i.sort((e,t)=>e.openStart-t.openStart||t.closeEnd-e.closeEnd)}function ye(e,t={}){let{includeEm:n=!0,includeStrong:r=!0}=t,i=ve(e,t).filter(e=>e.type===`em`?n:r);if(i.length===0)return e;let a=/* @__PURE__ */ new Map,o=e=>(a.has(e)||a.set(e,{openEnd:[],closeEnd:[],openStart:[],closeStart:[]}),a.get(e));for(let e of i){let t=e.type;o(e.openStart).openStart.push(`<${t}><span class="syntax-marker">`),o(e.openEnd).openEnd.push(`</span>`),o(e.closeStart).closeStart.push(`<span class="syntax-marker">`),o(e.closeEnd).closeEnd.push(`</span></${t}>`)}let s=``,c=0;for(let t of[...a.keys()].sort((e,t)=>e-t)){s+=e.slice(c,t);let n=a.get(t);s+=n.openEnd.join(``),s+=n.closeEnd.join(``),s+=n.openStart.join(``),s+=n.closeStart.join(``),c=t}return s+e.slice(c)}function S(e){return e.replace(/&nbsp;/g,` `).replace(/&quot;/g,`"`).replace(/&#39;/g,`'`).replace(/&lt;/g,`<`).replace(/&gt;/g,`>`).replace(/&amp;/g,`&`)}var MarkdownParser=class{static resolveDisabled(e){if(!e||e.length===0)return this.noneDisabled;let t=new Set(e);return t.has(`headings`)&&[`h1`,`h2`,`h3`].forEach(e=>t.add(e)),t.has(`lists`)&&t.add(`tasks`),t}static resetLinkIndex(){this.linkIndex=0}static setCodeHighlighter(e){this.codeHighlighter=e}static setCustomSyntax(e){this.customSyntax=e}static applyCustomSyntax(e,t=this.customSyntax){return typeof t==`function`?t(e):e}static escapeHtml(e){let t={"&":`&amp;`,"<":`&lt;`,">":`&gt;`,'"':`&quot;`,"'":`&#39;`};return e.replace(/[&<>"']/g,e=>t[e])}static preserveIndentation(e,t){let n=t.match(/^(\s*)/)[1].replace(/ /g,`&nbsp;`);return e.replace(/^\s*/,n)}static parseHeader(e){let t=i(S(e));if(!t)return e;let n=t.indent.replace(/ /g,`&nbsp;`),r=this.escapeHtml(t.marker+t.separator),a=this.parseInlineElements(this.escapeHtml(t.content)),o=t.closing?`<span class="syntax-marker">${this.escapeHtml(t.closing)}</span>`:``;return`<h${t.level}>${n}<span class="syntax-marker">${r}</span>${a}${o}</h${t.level}>`}static parseHorizontalRule(e){let t=S(e);return a(t)?`<div><span class="hr-marker">${this.preserveIndentation(this.escapeHtml(t),t)}</span></div>`:null}static parseBlockquote(e){let t=o(S(e));return t?`${t.indent.replace(/ /g,`&nbsp;`)}<span class="blockquote"><span class="syntax-marker">${this.escapeHtml(t.marker)}</span>${this.escapeHtml(t.separator)}${this.parseInlineElements(this.escapeHtml(t.content))}</span>`:e}static parseBulletList(e){let t=S(e);if(a(t))return e;let n=s(t);return!n||n.listType!==`bullet`?e:`${n.indent.replace(/ /g,`&nbsp;`)}<li class="bullet-list"><span class="syntax-marker">${this.escapeHtml(n.marker+n.separator)}</span>${this.parseInlineElements(this.escapeHtml(n.content))}</li>`}static parseTaskList(e,t=!1){return e.replace(/^((?:&nbsp;)*)-(\s+)\[([ xX])\](\s*)(.*)$/,(e,n,r,i,a,o)=>a===``&&o!==``?e:(o=this.parseInlineElements(o),t?`<li class="task-list">${n}<input type="checkbox" ${i.toLowerCase()===`x`?`checked`:``}> ${o}</li>`:`<li class="task-list">${n}<span class="syntax-marker">-${r}[${i}]${a}</span>${o}</li>`))}static parseNumberedList(e){let t=s(S(e));return!t||t.listType!==`ordered`?e:`${t.indent.replace(/ /g,`&nbsp;`)}<li class="ordered-list"><span class="syntax-marker">${this.escapeHtml(t.marker+t.separator)}</span>${this.parseInlineElements(this.escapeHtml(t.content))}</li>`}static parseCodeBlock(e){let t=c(S(e));return t?this.renderFence(t):null}static renderFence(e,t=!1){let n=this.preserveIndentation(this.escapeHtml(e.source),e.source);return`<div${t?` class="raw-line"`:``}><span class="code-fence">${n}</span></div>`}static renderCodeContent(e,t,n,r=0,i=-1){let a=e.map(e=>{let t=0;for(;t<r&&e[t]===` `;)t++;return{source:e,prefix:e.slice(0,t),content:e.slice(t)}}),o=a.map(e=>e.content).join(`
`),s=e=>e?`<span class="syntax-marker">${this.escapeHtml(e)}</span>`:``,c=a.map((e,t)=>t===i?`<span class="raw-line">${this.escapeHtml(e.source)||`&nbsp;`}</span>`:e.prefix===``&&e.content===``?`<span class="syntax-marker">&nbsp;</span>`:s(e.prefix)+this.escapeHtml(e.content)).join(`
`),l=t.split(/[\t ]/,1)[0],u=l?` class="language-${this.escapeHtml(l)}"`:``,d=n||this.codeHighlighter,f=c;if(d)try{let e=d(o,l);if(e&&typeof e.then==`function`)console.warn(`Async highlighters are not supported in parse() because it returns an HTML string. Use synchronous highlighters only.`);else if(e&&typeof e==`string`&&e.trim()){let t=e.split(`
`);t.length===a.length+1&&t[t.length-1]===``&&t.pop(),t.length===a.length?f=t.map((e,t)=>t===i?`<span class="raw-line">${this.escapeHtml(a[t].source)||`&nbsp;`}</span>`:s(a[t].prefix)+e).join(`
`):console.warn(`Code highlighter output line count does not match the source. Using unhighlighted code to preserve alignment.`)}}catch(e){console.warn(`Code highlighting failed:`,e)}return`<pre class="code-block"><code${u}>${f}</code></pre>`}static parseBold(e){return ye(e,{htmlEntities:!0,includeEm:!1})}static parseItalic(e){return ye(e,{htmlEntities:!0,includeStrong:!1})}static parseEmphasis(e){return ye(e,{htmlEntities:!0})}static parseStrikethrough(e){return e=e.replace(/* @__PURE__ */ RegExp(`(?<!~)~~(?!~)(.+?)(?<!~)~~(?!~)`,`g`),`<del><span class="syntax-marker">~~</span>$1<span class="syntax-marker">~~</span></del>`),e=e.replace(/* @__PURE__ */ RegExp(`(?<!~)~(?!~)(.+?)(?<!~)~(?!~)`,`g`),`<del><span class="syntax-marker">~</span>$1<span class="syntax-marker">~</span></del>`),e}static parseInlineCode(e){let t=b(e);for(let n of t.reverse()){let t=`<code><span class="syntax-marker">${n.openTicks}</span>${n.content}<span class="syntax-marker">${n.closeTicks}</span></code>`;e=e.slice(0,n.start)+t+e.slice(n.end)}return e}static sanitizeUrl(e){let t=e.trim(),n=t.toLowerCase(),r=[`http://`,`https://`,`mailto:`,`ftp://`,`ftps://`].some(e=>n.startsWith(e)),i=t.startsWith(`/`)||t.startsWith(`#`)||t.startsWith(`?`)||t.startsWith(`.`)||!t.includes(`:`)&&!t.includes(`//`);return r||i?e:`#`}static findLinks(e,t={}){let{allowEmptyText:n=!1,...r}=t;return y(e,r).filter(e=>(n||e.text.raw.length>0)&&e.destination!==null&&e.destination.value.length>0)}static findRenderableLinks(e,t={}){let{allowEmptyText:n=!1,...r}=t;return ne(e,r).filter(e=>(n||e.text.raw.length>0)&&e.destination!==null&&e.destination.value.length>0)}static parseLinks(e){let t=this.findLinks(e,{htmlEntities:!0});t.forEach(e=>{e.anchorName=`--link-${this.linkIndex++}`});for(let n of t.reverse()){let t=this.escapeHtml(this.sanitizeUrl(n.destination.value)),r=n.title===null?``:` title="${this.escapeHtml(n.title.value)}"`,i=e.slice(n.text.start,n.text.end),a=e.slice(n.text.end,n.end),o=`<a href="${t}"${r} style="anchor-name: ${n.anchorName}"><span class="syntax-marker">[</span>${i}<span class="syntax-marker url-part">${a}</span></a>`;e=e.slice(0,n.start)+o+e.slice(n.end)}return e}static identifyAndProtectSanctuaries(e){let t=/* @__PURE__ */ new Map,n=0,r=e,i=b(e,(e.includes(`[`)?this.findRenderableLinks(e,{htmlEntities:!0}):[]).map(e=>({start:e.text.end,end:e.end})));i.sort((e,t)=>t.start-e.start),i.forEach(e=>{let i=`\uE000${n++}\uE001`;t.set(i,{type:`code`,original:e.raw,openTicks:e.openTicks,content:e.content,closeTicks:e.closeTicks}),r=r.substring(0,e.start)+i+r.substring(e.end)});let a=[...t.keys()];return(r.includes(`[`)?this.findLinks(r,{htmlEntities:!0}):[]).filter(e=>{let t=r.slice(e.text.end,e.end);return a.every(e=>!t.includes(e))}).sort((e,t)=>t.start-e.start).forEach(e=>{var i,a;let o=`\uE000${n++}\uE001`;t.set(o,{type:`link`,original:r.slice(e.start,e.end),linkText:r.slice(e.text.start,e.text.end),tail:r.slice(e.text.end,e.end),url:e.destination.value,title:(a=(i=e.title)==null?void 0:i.value)==null?null:a}),r=r.slice(0,e.start)+o+r.slice(e.end)}),{protectedText:r,sanctuaries:t}}static restoreAndTransformSanctuaries(e,t){return Array.from(t.keys()).sort((t,n)=>e.indexOf(t)-e.indexOf(n)).forEach(n=>{let r=t.get(n),i;if(r.type===`code`)i=`<code><span class="syntax-marker">${r.openTicks}</span>${r.content}<span class="syntax-marker">${r.closeTicks}</span></code>`;else if(r.type===`link`){let e=r.linkText;e=this.parseStrikethrough(e),e=this.parseEmphasis(e),t.forEach((t,n)=>{if(e.includes(n)&&t.type===`code`){let r=`<code><span class="syntax-marker">${t.openTicks}</span>${t.content}<span class="syntax-marker">${t.closeTicks}</span></code>`;e=e.replace(n,()=>r)}});let n=`--link-${this.linkIndex++}`;i=`<a href="${this.escapeHtml(this.sanitizeUrl(r.url))}"${r.title===null?``:` title="${this.escapeHtml(r.title)}"`} style="anchor-name: ${n}"><span class="syntax-marker">[</span>${e}<span class="syntax-marker url-part">${r.tail}</span></a>`}e=e.replace(n,()=>i)}),e}static parseInlineElements(e){let{protectedText:t,sanctuaries:n}=this.identifyAndProtectSanctuaries(e),r=t;return r=this.parseStrikethrough(r),r=this.parseEmphasis(r),r=this.restoreAndTransformSanctuaries(r,n),r}static parseLine(e,t=!1,n=this.noneDisabled){if(e===``)return`<div>&nbsp;</div>`;let r=a(e);if(r&&!n.has(`hr`))return`<div><span class="hr-marker">${this.preserveIndentation(this.escapeHtml(e),e)}</span></div>`;let l=!n.has(`code`)&&c(e);if(l)return this.renderFence(l);let u=i(e);if(u&&!n.has(`h${u.level}`)){let e=u.indent.replace(/ /g,`&nbsp;`),t=this.escapeHtml(u.marker+u.separator),n=this.parseInlineElements(this.escapeHtml(u.content)),r=u.closing?`<span class="syntax-marker">${this.escapeHtml(u.closing)}</span>`:``;return`<div><h${u.level}>${e}<span class="syntax-marker">${t}</span>${n}${r}</h${u.level}></div>`}let d=!n.has(`blockquote`)&&o(e);if(d)return`<div>${d.indent.replace(/ /g,`&nbsp;`)}<span class="blockquote"><span class="syntax-marker">${this.escapeHtml(d.marker)}</span>${this.escapeHtml(d.separator)}${this.parseInlineElements(this.escapeHtml(d.content))}</span></div>`;let f=this.preserveIndentation(this.escapeHtml(e),e),p=n.has(`tasks`)?f:this.parseTaskList(f,t);if(p!==f)return`<div>${p}</div>`;let m=!n.has(`lists`)&&!r&&s(e);if(m){let e=m.indent.replace(/ /g,`&nbsp;`),t=this.escapeHtml(m.marker+m.separator),n=this.parseInlineElements(this.escapeHtml(m.content));return`<div>${e}<li class="${m.listType===`bullet`?`bullet-list`:`ordered-list`}"><span class="syntax-marker">${t}</span>${n}</li></div>`}let h=/^[\t ]*/.exec(e)[0];return f=h.replace(/ /g,`&nbsp;`)+this.parseInlineElements(this.escapeHtml(e.slice(h.length))),`<div>${f}</div>`}static parse(e,t=-1,n=!1,r,i=!1,a={}){var o;let s=(o=a.customSyntax)==null?this.customSyntax:o,u=this.resolveDisabled(a.disable);this.resetLinkIndex();let d=e.split(`
`),f=[],p=null,m=[],h=-1;for(let e=0;e<d.length;e++){let a=d[e],o=n&&e===t;if(p){let e=l(a,p);if(e){f.push(this.renderCodeContent(m,p.info,r,p.indent.length,h));let t=this.renderFence(e,o);f.push(o?t:this.applyCustomSyntax(t,s)),p=null,m=[],h=-1}else o&&(h=m.length),m.push(a);continue}let g=!u.has(`code`)&&c(a);if(g){p=g;let e=this.renderFence(g,o);f.push(o?e:this.applyCustomSyntax(e,s));continue}if(o){let e=this.escapeHtml(a)||`&nbsp;`;f.push(`<div class="raw-line">${e}</div>`);continue}f.push(this.applyCustomSyntax(this.parseLine(a,i,u),s))}p&&m.length>0&&f.push(this.renderCodeContent(m,p.info,r,p.indent.length,h));let g=f.join(``);return this.postProcessHTML(g,r,!1)}static postProcessHTML(e,t,n=!0){return this.postProcessHTMLManual(e,t,n)}static postProcessHTMLManual(e,t,n=!0){let r=e;return r=r.replace(/((?:<div(?:\s[^>]*)?>(?:&nbsp;)*<li class="bullet-list">.*?<\/li><\/div>\s*)+)/gs,e=>{let t=e.match(/<div(?:\s[^>]*)?>(?:&nbsp;)*<li class="bullet-list">.*?<\/li><\/div>/gs)||[];return t.length>0?`<ul>`+t.map(e=>{let t=e.match(/<div(?:\s[^>]*)?>((?:&nbsp;)*)<li/),n=e.match(/<li class="bullet-list">.*?<\/li>/);if(t&&n){let e=t[1];return n[0].replace(/<li class="bullet-list">/,`<li class="bullet-list">${e}`)}return n?n[0]:``}).filter(Boolean).join(``)+`</ul>`:e}),r=r.replace(/((?:<div(?:\s[^>]*)?>(?:&nbsp;)*<li class="ordered-list">.*?<\/li><\/div>\s*)+)/gs,e=>{let t=e.match(/<div(?:\s[^>]*)?>(?:&nbsp;)*<li class="ordered-list">.*?<\/li><\/div>/gs)||[];if(t.length>0){let e=t.map(e=>{let t=e.match(/<div(?:\s[^>]*)?>((?:&nbsp;)*)<li/),n=e.match(/<li class="ordered-list">.*?<\/li>/);if(t&&n){let e=t[1];return n[0].replace(/<li class="ordered-list">/,`<li class="ordered-list">${e}`)}return n?n[0]:``}).filter(Boolean),n=t[0].match(/<span class="syntax-marker">(\d+)\./),r=n?Number.parseInt(n[1],10):1;return`<ol${r===1?``:` start="${r}"`}>`+e.join(``)+`</ol>`}return e}),n&&(r=r.replace(/<div><span class="code-fence">(```[^<]*)<\/span><\/div>(.*?)<div><span class="code-fence">(```)<\/span><\/div>/gs,(e,n,r,i)=>{if(r.includes(`<pre class="code-block">`))return e;let a=(r.match(/<div>(.*?)<\/div>/gs)||[]).map(e=>e.replace(/<div>(.*?)<\/div>/s,`$1`)),o=a.map(e=>e===`&nbsp;`?``:e.replace(/&nbsp;/g,` `)).join(`
`),s=a.join(`
`),c=n.slice(3).trim(),l=c?` class="language-${c}"`:``,u=s,d=t||this.codeHighlighter;if(d)try{let e=d(o.replace(/&quot;/g,`"`).replace(/&#39;/g,`'`).replace(/&lt;/g,`<`).replace(/&gt;/g,`>`).replace(/&amp;/g,`&`),c);e&&typeof e.then==`function`?console.warn(`Async highlighters are not supported in Node.js (non-DOM) context. Use synchronous highlighters for server-side rendering.`):e&&typeof e==`string`&&e.trim()&&(u=e)}catch(e){console.warn(`Code highlighting failed:`,e)}let f=`<div><span class="code-fence">${n}</span></div>`;return f+=`<pre class="code-block"><code${l}>${u}</code></pre>`,f+=`<div><span class="code-fence">${i}</span></div>`,f})),r}static getListContext(e,t,n=this.noneDisabled){let r=e.split(`
`),i=0,o=0,c=0;for(let e=0;e<r.length;e++){let n=r[e].length;if(i+n>=t){o=e,c=i;break}i+=n+1}let l=r[o],u=c+l.length,d={inList:!1,listType:null,indent:``,marker:null,content:l,lineStart:c,lineEnd:u,markerEndPos:c};if(a(l))return d;let f=s(l);if(!f)return d;let p=!n.has(`tasks`)&&f.listType===`bullet`&&f.marker===`-`?/^\[([ xX])\]([\t ]*)(.*)$/.exec(f.content):null;return p&&(p[2]!==``||p[3]===``)?{inList:!0,listType:`checkbox`,indent:f.indent,marker:`-`,checked:p[1].toLowerCase()===`x`,content:p[3],lineStart:c,lineEnd:u,markerEndPos:c+f.indent.length+f.marker.length+f.separator.length+3+p[2].length}:f.listType===`bullet`?{inList:!0,listType:`bullet`,indent:f.indent,marker:f.marker,content:f.content,lineStart:c,lineEnd:u,markerEndPos:c+f.indent.length+f.marker.length+f.separator.length}:{inList:!0,listType:`numbered`,indent:f.indent,marker:Number.parseInt(f.marker,10),content:f.content,lineStart:c,lineEnd:u,markerEndPos:c+f.indent.length+f.marker.length+f.separator.length}}static createNewListItem(e){switch(e.listType){case`bullet`:return`${e.indent}${e.marker} `;case`numbered`:return`${e.indent}${e.marker+1}. `;case`checkbox`:return`${e.indent}- [ ] `;default:return``}}static renumberLists(e){let t=e.split(`
`),n=/* @__PURE__ */ new Map,r=!1;return t.map(e=>{let t=e.match(this.LIST_PATTERNS.numbered);if(t){let e=t[1],i=e.length,a=t[3];r||n.clear();let o=(n.get(i)||0)+1;n.set(i,o);for(let[e]of n)e>i&&n.delete(e);return r=!0,`${e}${o}. ${a}`}else return(e.trim()===``||!e.match(/^\s/))&&(r=!1,n.clear()),e}).join(`
`)}};r(MarkdownParser,`linkIndex`,0),r(MarkdownParser,`codeHighlighter`,null),r(MarkdownParser,`customSyntax`,null),r(MarkdownParser,`noneDisabled`,/* @__PURE__ */ new Set),r(MarkdownParser,`LIST_PATTERNS`,{bullet:/^( *)([-*+])[\t ]+(.*)$/,numbered:/^( *)(\d{1,9})\.[\t ]+(.*)$/,checkbox:/^( *)-[\t ]+\[([ xX])\][\t ]+(.*)$/});var ShortcutsManager=class{constructor(e){this.editor=e}handleKeydown(e){if(!(navigator.platform.toLowerCase().includes(`mac`)?e.metaKey:e.ctrlKey))return!1;if(e.key===`]`)return e.preventDefault(),this.editor.indentSelection(),!0;if(e.key===`[`)return e.preventDefault(),this.editor.outdentSelection(),!0;let t=null;switch(e.key.toLowerCase()){case`b`:e.shiftKey||(t=`toggleBold`);break;case`i`:e.shiftKey||(t=`toggleItalic`);break;case`k`:e.shiftKey||(t=`insertLink`);break;case`7`:e.shiftKey&&(t=`toggleNumberedList`);break;case`8`:e.shiftKey&&(t=`toggleBulletList`);break}return t?(e.preventDefault(),this.editor.performAction(t,e),!0):!1}destroy(){}},C={name:`solar`,colors:{bgPrimary:`#faf0ca`,bgSecondary:`#ffffff`,text:`#0d3b66`,textPrimary:`#0d3b66`,textSecondary:`#5a7a9b`,h1:`#f95738`,h2:`#ee964b`,h3:`#3d8a51`,strong:`#ee964b`,em:`#f95738`,del:`#ee964b`,link:`#0d3b66`,code:`#0d3b66`,codeBg:`rgba(244, 211, 94, 0.4)`,blockquote:`#5a7a9b`,hr:`#5a7a9b`,syntaxMarker:`rgba(13, 59, 102, 0.52)`,syntax:`#999999`,cursor:`#f95738`,selection:`rgba(244, 211, 94, 0.4)`,listMarker:`#ee964b`,rawLine:`#5a7a9b`,border:`#e0e0e0`,hoverBg:`#f0f0f0`,primary:`#0d3b66`,toolbarBg:`#ffffff`,toolbarIcon:`#0d3b66`,toolbarHover:`#f5f5f5`,toolbarActive:`#faf0ca`,placeholder:`#999999`},previewColors:{text:`#0d3b66`,h1:`inherit`,h2:`inherit`,h3:`inherit`,strong:`inherit`,em:`inherit`,link:`#0d3b66`,code:`#0d3b66`,codeBg:`rgba(244, 211, 94, 0.4)`,blockquote:`#5a7a9b`,hr:`#5a7a9b`,bg:`transparent`}},be={name:`cave`,colors:{bgPrimary:`#141E26`,bgSecondary:`#1D2D3E`,text:`#c5dde8`,textPrimary:`#c5dde8`,textSecondary:`#9fcfec`,h1:`#d4a5ff`,h2:`#f6ae2d`,h3:`#9fcfec`,strong:`#f6ae2d`,em:`#9fcfec`,del:`#f6ae2d`,link:`#9fcfec`,code:`#c5dde8`,codeBg:`#1a232b`,blockquote:`#9fcfec`,hr:`#c5dde8`,syntaxMarker:`rgba(159, 207, 236, 0.73)`,syntax:`#7a8c98`,cursor:`#f26419`,selection:`rgba(51, 101, 138, 0.4)`,listMarker:`#f6ae2d`,rawLine:`#9fcfec`,border:`#2a3f52`,hoverBg:`#243546`,primary:`#9fcfec`,toolbarBg:`#1D2D3E`,toolbarIcon:`#c5dde8`,toolbarHover:`#243546`,toolbarActive:`#2a3f52`,placeholder:`#6a7a88`},previewColors:{text:`#c5dde8`,h1:`inherit`,h2:`inherit`,h3:`inherit`,strong:`inherit`,em:`inherit`,link:`#9fcfec`,code:`#c5dde8`,codeBg:`#1a232b`,blockquote:`#9fcfec`,hr:`#c5dde8`,bg:`transparent`}},xe={solar:C,cave:be,auto:C,light:C,dark:be};function w(e){return typeof e==`string`?{...xe[e]||xe.solar,name:e}:e}function Se(e){if(e!==`auto`)return e;let t=window.matchMedia&&window.matchMedia(`(prefers-color-scheme: dark)`);return t!=null&&t.matches?`cave`:`solar`}function Ce(e,t){let n=[];for(let[t,r]of Object.entries(e)){let e=t.replace(/([A-Z])/g,`-$1`).toLowerCase();n.push(`--${e}: ${r};`)}if(t)for(let[e,r]of Object.entries(t)){let t=e.replace(/([A-Z])/g,`-$1`).toLowerCase();n.push(`--preview-${t}-default: ${r};`)}return n.join(`
`)}function we(e,t={},n={}){return{...e,colors:{...e.colors,...t},previewColors:{...e.previewColors,...n}}}var T={fontSize:`14px`,lineHeight:1.6,fontFamily:`"SF Mono", SFMono-Regular, Menlo, Monaco, "Cascadia Code", Consolas, "Roboto Mono", "Noto Sans Mono", "Droid Sans Mono", "Ubuntu Mono", "DejaVu Sans Mono", "Liberation Mono", "Courier New", Courier, monospace`,padding:`20px`};function Te(e={}){let{fontSize:t=T.fontSize,lineHeight:n=T.lineHeight,fontFamily:r=T.fontFamily,padding:i=T.padding,theme:a=null,mobile:o={}}=e,s=Object.keys(o).length>0?`
    @media (max-width: 640px) {
      .overtype-wrapper .overtype-input,
      .overtype-wrapper .overtype-preview {
        ${Object.entries(o).map(([e,t])=>`${e.replace(/([A-Z])/g,`-$1`).toLowerCase()}: ${t} !important;`).join(`
        `)}
      }
    }
  `:``,c=a&&a.colors?Ce(a.colors,a.previewColors):``;return`
    /* OverType Editor Styles */
    
    /* Middle-ground CSS Reset - Prevent parent styles from leaking in */
    .overtype-container * {
      /* Box model - these commonly leak */
      margin: 0 !important;
      padding: 0 !important;
      border: 0 !important;
      
      /* Layout - these can break our layout */
      /* Don't reset position - it breaks dropdowns */
      float: none !important;
      clear: none !important;
      
      /* Typography - only reset decorative aspects */
      text-decoration: none !important;
      text-transform: none !important;
      letter-spacing: normal !important;
      
      /* Visual effects that can interfere */
      box-shadow: none !important;
      text-shadow: none !important;
      
      /* Ensure box-sizing is consistent */
      box-sizing: border-box !important;
      
      /* Keep inheritance for these */
      /* font-family, color, line-height, font-size - inherit */
    }
    
    /* Container base styles after reset */
    .overtype-container {
      display: flex !important;
      flex-direction: column !important;
      width: 100% !important;
      height: 100% !important;
      position: relative !important; /* Override reset - needed for absolute children */
      overflow: visible !important; /* Allow dropdown to overflow container */
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
      text-align: left !important;
      ${c?`
      /* Theme Variables */
      ${c}`:``}
    }
    
    /* Force left alignment for all elements in the editor */
    .overtype-container .overtype-wrapper * {
      text-align: left !important;
    }
    
    /* Auto-resize mode styles */
    .overtype-container.overtype-auto-resize {
      height: auto !important;
    }

    .overtype-container.overtype-auto-resize .overtype-wrapper {
      flex: 0 0 auto !important; /* Don't grow/shrink, use explicit height */
      height: auto !important;
      min-height: 60px !important;
      overflow: visible !important;
    }
    
    .overtype-wrapper {
      position: relative !important; /* Override reset - needed for absolute children */
      width: 100% !important;
      flex: 1 1 0 !important; /* Grow to fill remaining space, with flex-basis: 0 */
      min-height: 60px !important; /* Minimum usable height */
      overflow: hidden !important;
      background: var(--bg-secondary, #ffffff) !important;
      z-index: 1; /* Below toolbar and dropdown */
    }

    /* Critical alignment styles - must be identical for both layers */
    .overtype-wrapper .overtype-input,
    .overtype-wrapper .overtype-preview {
      /* Positioning - must be identical */
      position: absolute !important; /* Override reset - required for overlay */
      top: 0 !important;
      left: 0 !important;
      width: 100% !important;
      height: 100% !important;

      /* Font properties - any difference breaks alignment */
      font-family: var(--instance-font-family, ${r}) !important;
      font-variant-ligatures: none !important; /* keep metrics stable for code */
      font-size: var(--instance-font-size, ${t}) !important;
      line-height: var(--instance-line-height, ${n}) !important;
      font-weight: normal !important;
      font-style: normal !important;
      font-variant: normal !important;
      font-stretch: normal !important;
      font-kerning: none !important;
      font-feature-settings: normal !important;
      
      /* Box model - must match exactly */
      padding: var(--instance-padding, ${i}) !important;
      margin: 0 !important;
      border: none !important;
      outline: none !important;
      box-sizing: border-box !important;
      
      /* Text layout - critical for character positioning */
      white-space: pre-wrap !important;
      word-wrap: break-word !important;
      word-break: normal !important;
      overflow-wrap: break-word !important;
      tab-size: 2 !important;
      -moz-tab-size: 2 !important;
      text-align: left !important;
      text-indent: 0 !important;
      letter-spacing: normal !important;
      word-spacing: normal !important;
      
      /* Text rendering */
      text-transform: none !important;
      text-rendering: auto !important;
      -webkit-font-smoothing: auto !important;
      -webkit-text-size-adjust: 100% !important;
      
      /* Direction and writing */
      direction: ltr !important;
      writing-mode: horizontal-tb !important;
      unicode-bidi: normal !important;
      text-orientation: mixed !important;
      
      /* Visual effects that could shift perception */
      text-shadow: none !important;
      filter: none !important;
      transform: none !important;
      zoom: 1 !important;
      
      /* Vertical alignment */
      vertical-align: baseline !important;
      
      /* Size constraints */
      min-width: 0 !important;
      min-height: 0 !important;
      max-width: none !important;
      max-height: none !important;
      
      /* Overflow */
      overflow-y: auto !important;
      overflow-x: auto !important;
      /* overscroll-behavior removed to allow scroll-through to parent */
      scrollbar-width: auto !important;
      scrollbar-gutter: auto !important;
      
      /* Animation/transition - disabled to prevent movement */
      animation: none !important;
      transition: none !important;
    }

    /* Input layer styles */
    .overtype-wrapper .overtype-input {
      /* Layer positioning */
      z-index: 1 !important;
      
      /* Text visibility */
      color: transparent !important;
      caret-color: var(--cursor, #f95738) !important;
      background-color: transparent !important;
      
      /* Textarea-specific */
      resize: none !important;
      appearance: none !important;
      -webkit-appearance: none !important;
      -moz-appearance: none !important;
      
      /* Prevent mobile zoom on focus */
      touch-action: manipulation !important;
      
      /* Disable autofill */
      autocomplete: off !important;
      autocorrect: off !important;
      autocapitalize: off !important;
    }

    .overtype-wrapper .overtype-input::selection {
      background-color: var(--selection, rgba(244, 211, 94, 0.4));
    }

    .overtype-wrapper .overtype-input::placeholder {
      color: transparent !important;
    }

    /* Placeholder shim - visible when textarea is empty */
    .overtype-wrapper .overtype-placeholder {
      position: absolute !important;
      top: 0 !important;
      left: 0 !important;
      width: 100% !important;
      z-index: 0 !important;
      pointer-events: none !important;
      user-select: none !important;
      font-family: var(--instance-font-family, ${r}) !important;
      font-size: var(--instance-font-size, ${t}) !important;
      line-height: var(--instance-line-height, ${n}) !important;
      padding: var(--instance-padding, ${i}) !important;
      box-sizing: border-box !important;
      color: var(--placeholder, #999) !important;
    }

    /* Preview layer styles */
    .overtype-wrapper .overtype-preview {
      /* Layer positioning */
      z-index: 0 !important;
      pointer-events: none !important;
      color: var(--text, #0d3b66) !important;
      background-color: transparent !important;
      
      /* Prevent text selection */
      user-select: none !important;
      -webkit-user-select: none !important;
      -moz-user-select: none !important;
      -ms-user-select: none !important;
    }

    /* Prevent external resets (Tailwind, Bootstrap, etc.) from breaking alignment.
       Any element whose font metrics differ from the textarea causes the CSS "strut"
       to inflate line boxes, drifting the overlay. Force inheritance so every element
       inside the preview matches the textarea exactly. */
    .overtype-wrapper .overtype-preview * {
      font-family: inherit !important;
      font-size: inherit !important;
      line-height: inherit !important;
    }

    /* Defensive styles for preview child divs */
    .overtype-wrapper .overtype-preview div {
      /* Reset any inherited styles */
      margin: 0 !important;
      padding: 0 !important;
      border: none !important;
      text-align: left !important;
      text-indent: 0 !important;
      display: block !important;
      position: static !important;
      transform: none !important;
      min-height: 0 !important;
      max-height: none !important;
      line-height: inherit !important;
      font-size: inherit !important;
      font-family: inherit !important;
    }

    /* Markdown element styling - NO SIZE CHANGES */
    .overtype-wrapper .overtype-preview .header {
      font-weight: bold !important;
    }

    /* Header colors */
    .overtype-wrapper .overtype-preview .h1 { 
      color: var(--h1, #f95738) !important; 
    }
    .overtype-wrapper .overtype-preview .h2 { 
      color: var(--h2, #ee964b) !important; 
    }
    .overtype-wrapper .overtype-preview .h3 { 
      color: var(--h3, #3d8a51) !important; 
    }

    /* Semantic headers - flatten in edit mode */
    .overtype-wrapper .overtype-preview h1,
    .overtype-wrapper .overtype-preview h2,
    .overtype-wrapper .overtype-preview h3 {
      font-size: inherit !important;
      font-weight: bold !important;
      margin: 0 !important;
      padding: 0 !important;
      display: inline !important;
      line-height: inherit !important;
    }

    /* Header colors for semantic headers */
    .overtype-wrapper .overtype-preview h1 { 
      color: var(--h1, #f95738) !important; 
    }
    .overtype-wrapper .overtype-preview h2 { 
      color: var(--h2, #ee964b) !important; 
    }
    .overtype-wrapper .overtype-preview h3 { 
      color: var(--h3, #3d8a51) !important; 
    }

    /* Lists - remove styling in edit mode */
    .overtype-wrapper .overtype-preview ul,
    .overtype-wrapper .overtype-preview ol {
      list-style: none !important;
      margin: 0 !important;
      padding: 0 !important;
      display: block !important; /* Lists need to be block for line breaks */
    }

    .overtype-wrapper .overtype-preview li {
      display: block !important; /* Each item on its own line */
      margin: 0 !important;
      padding: 0 !important;
      /* Don't set list-style here - let ul/ol control it */
    }

    /* Bold text */
    .overtype-wrapper .overtype-preview strong {
      color: var(--strong, #ee964b) !important;
      font-weight: bold !important;
    }

    /* Italic text */
    .overtype-wrapper .overtype-preview em {
      color: var(--em, #f95738) !important;
      text-decoration-color: var(--em, #f95738) !important;
      text-decoration-thickness: 1px !important;
      font-style: italic !important;
    }

    /* Strikethrough text */
    .overtype-wrapper .overtype-preview del {
      color: var(--del, #ee964b) !important;
      text-decoration: line-through !important;
      text-decoration-color: var(--del, #ee964b) !important;
      text-decoration-thickness: 1px !important;
    }

    /* Inline code */
    .overtype-wrapper .overtype-preview code {
      background: var(--code-bg, rgba(244, 211, 94, 0.4)) !important;
      color: var(--code, #0d3b66) !important;
      padding: 0 !important;
      border-radius: 2px !important;
      font-family: inherit !important;
      font-size: inherit !important;
      line-height: inherit !important;
      font-weight: normal !important;
    }

    /* Code blocks - consolidated pre blocks */
    .overtype-wrapper .overtype-preview pre {
      padding: 0 !important;
      margin: 0 !important;
      border-radius: 4px !important;
      overflow-x: auto !important;
    }
    
    /* Code block styling in normal mode - yellow background */
    .overtype-wrapper .overtype-preview pre.code-block {
      background: var(--code-bg, rgba(244, 211, 94, 0.4)) !important;
      white-space: break-spaces !important; /* Prevent horizontal scrollbar that breaks alignment */
    }

    /* Code inside pre blocks - remove background */
    .overtype-wrapper .overtype-preview pre code {
      background: transparent !important;
      color: var(--code, #0d3b66) !important;
      font-family: var(--instance-font-family, ${r}) !important; /* Match textarea font exactly for alignment */
    }

    /* Blockquotes */
    .overtype-wrapper .overtype-preview .blockquote {
      color: var(--blockquote, #5a7a9b) !important;
      padding: 0 !important;
      margin: 0 !important;
      border: none !important;
    }

    /* Links */
    .overtype-wrapper .overtype-preview a {
      color: var(--link, #0d3b66) !important;
      text-decoration: underline !important;
      font-weight: normal !important;
    }

    .overtype-wrapper .overtype-preview a:hover {
      text-decoration: underline !important;
      color: var(--link, #0d3b66) !important;
    }

    /* Lists - no list styling */
    .overtype-wrapper .overtype-preview ul,
    .overtype-wrapper .overtype-preview ol {
      list-style: none !important;
      margin: 0 !important;
      padding: 0 !important;
    }


    /* Horizontal rules */
    .overtype-wrapper .overtype-preview hr {
      border: none !important;
      color: var(--hr, #5a7a9b) !important;
      margin: 0 !important;
      padding: 0 !important;
    }

    .overtype-wrapper .overtype-preview .hr-marker {
      color: var(--hr, #5a7a9b) !important;
      opacity: 0.6 !important;
    }

    /* Code fence markers - with background when not in code block */
    .overtype-wrapper .overtype-preview .code-fence {
      color: var(--code, #0d3b66) !important;
      background: var(--code-bg, rgba(244, 211, 94, 0.4)) !important;
    }
    
    /* Code block lines - background for entire code block */
    .overtype-wrapper .overtype-preview .code-block-line {
      background: var(--code-bg, rgba(244, 211, 94, 0.4)) !important;
    }
    
    /* Remove background from code fence when inside code block line */
    .overtype-wrapper .overtype-preview .code-block-line .code-fence {
      background: transparent !important;
    }

    /* Raw markdown line */
    .overtype-wrapper .overtype-preview .raw-line {
      color: var(--raw-line, #5a7a9b) !important;
      font-style: normal !important;
      font-weight: normal !important;
    }

    /* Syntax markers */
    .overtype-wrapper .overtype-preview .syntax-marker {
      color: var(--syntax-marker, rgba(13, 59, 102, 0.52)) !important;
      opacity: 0.7 !important;
    }

    /* List markers */
    .overtype-wrapper .overtype-preview .list-marker {
      color: var(--list-marker, #ee964b) !important;
    }

    /* Stats bar */
    
    /* Stats bar - positioned by flexbox */
    .overtype-stats {
      height: 40px !important;
      padding: 0 20px !important;
      background: var(--bg-secondary, #f8f9fa) !important;
      border-top: 1px solid var(--border, #e0e0e0) !important;
      display: flex !important;
      justify-content: space-between !important;
      align-items: center !important;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif !important;
      font-size: 0.85rem !important;
      color: var(--text-secondary, #666) !important;
      flex-shrink: 0 !important; /* Don't shrink */
      z-index: 10001 !important; /* Above link tooltip */
      position: relative !important; /* Enable z-index */
    }


    .overtype-stats .overtype-stat {
      display: flex !important;
      align-items: center !important;
      gap: 5px !important;
      white-space: nowrap !important;
    }
    
    .overtype-stats .live-dot {
      width: 8px !important;
      height: 8px !important;
      background: #4caf50 !important;
      border-radius: 50% !important;
      animation: overtype-pulse 2s infinite !important;
    }
    
    @keyframes overtype-pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.6; transform: scale(1.2); }
    }
    

    /* Toolbar Styles */
    .overtype-toolbar.overtype-toolbar-hidden {
      display: none !important;
    }

    .overtype-toolbar {
      display: flex !important;
      align-items: center !important;
      gap: 4px !important;
      padding: 8px !important; /* Override reset */
      background: var(--toolbar-bg, var(--bg-primary, #f8f9fa)) !important; /* Override reset */
      border-bottom: 1px solid var(--toolbar-border, transparent) !important; /* Override reset */
      overflow-x: auto !important; /* Allow horizontal scrolling */
      overflow-y: hidden !important; /* Hide vertical overflow */
      -webkit-overflow-scrolling: touch !important;
      flex-shrink: 0 !important;
      height: auto !important;
      position: relative !important; /* Override reset */
      z-index: 100 !important; /* Ensure toolbar is above wrapper */
      scrollbar-width: thin; /* Thin scrollbar on Firefox */
    }
    
    /* Thin scrollbar styling */
    .overtype-toolbar::-webkit-scrollbar {
      height: 4px;
    }
    
    .overtype-toolbar::-webkit-scrollbar-track {
      background: transparent;
    }
    
    .overtype-toolbar::-webkit-scrollbar-thumb {
      background: rgba(0, 0, 0, 0.2);
      border-radius: 2px;
    }

    .overtype-toolbar-button {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 32px;
      height: 32px;
      padding: 0;
      border: none;
      border-radius: 6px;
      background: transparent;
      color: var(--toolbar-icon, var(--text-secondary, #666));
      cursor: pointer;
      transition: all 0.2s ease;
      flex-shrink: 0;
    }

    .overtype-toolbar-button svg {
      width: 20px;
      height: 20px;
      fill: currentColor;
    }

    .overtype-toolbar-button:hover {
      background: var(--toolbar-hover, var(--bg-secondary, #e9ecef));
      color: var(--toolbar-icon, var(--text-primary, #333));
    }

    .overtype-toolbar-button:active {
      transform: scale(0.95);
    }

    .overtype-toolbar-button.active {
      background: var(--toolbar-active, var(--primary, #007bff));
      color: var(--toolbar-icon, var(--text-primary, #333));
    }

    .overtype-toolbar-button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .overtype-toolbar-separator {
      width: 1px;
      height: 24px;
      background: var(--border, #e0e0e0);
      margin: 0 4px;
      flex-shrink: 0;
    }

    /* Adjust wrapper when toolbar is present */
    /* Mobile toolbar adjustments */
    @media (max-width: 640px) {
      .overtype-toolbar {
        padding: 6px;
        gap: 2px;
      }

      .overtype-toolbar-button {
        width: 36px;
        height: 36px;
      }

      .overtype-toolbar-separator {
        margin: 0 2px;
      }
    }
    
    /* Plain mode - hide preview and show textarea text */
    .overtype-container[data-mode="plain"] .overtype-preview {
      display: none !important;
    }
    
    .overtype-container[data-mode="plain"] .overtype-input {
      color: var(--text, #0d3b66) !important;
      /* Use system font stack for better plain text readability */
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, 
                   "Helvetica Neue", Arial, sans-serif !important;
    }
    
    /* Ensure textarea remains transparent in overlay mode */
    .overtype-container:not([data-mode="plain"]) .overtype-input {
      color: transparent !important;
    }

    /* Dropdown menu styles */
    .overtype-toolbar-button {
      position: relative !important; /* Override reset - needed for dropdown */
    }

    .overtype-toolbar-button.dropdown-active {
      background: var(--toolbar-active, var(--hover-bg, #f0f0f0));
    }

    .overtype-dropdown-menu {
      position: fixed !important; /* Fixed positioning relative to viewport */
      background: var(--bg-secondary, white) !important; /* Override reset */
      border: 1px solid var(--border, #e0e0e0) !important; /* Override reset */
      border-radius: 6px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1) !important; /* Override reset */
      z-index: 10000; /* Very high z-index to ensure visibility */
      min-width: 150px;
      padding: 4px 0 !important; /* Override reset */
      /* Position will be set via JavaScript based on button position */
    }

    .overtype-dropdown-item {
      display: flex;
      align-items: center;
      width: 100%;
      padding: 8px 12px;
      border: none;
      background: none;
      text-align: left;
      cursor: pointer;
      font-size: 14px;
      color: var(--text, #333);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }

    .overtype-dropdown-item:hover {
      background: var(--hover-bg, #f0f0f0);
    }

    .overtype-dropdown-item.active {
      font-weight: 600;
    }

    .overtype-dropdown-check {
      width: 16px;
      margin-right: 8px;
      color: var(--h1, #007bff);
    }

    .overtype-dropdown-icon {
      width: 20px;
      margin-right: 8px;
      text-align: center;
    }

    /* Preview mode styles */
    .overtype-container[data-mode="preview"] .overtype-input {
      display: none !important;
    }

    .overtype-container[data-mode="preview"] .overtype-preview {
      pointer-events: auto !important;
      user-select: text !important;
      cursor: text !important;
    }

    .overtype-container.overtype-auto-resize[data-mode="preview"] .overtype-preview {
      position: static !important;
      height: auto !important;
    }

    /* Hide syntax markers in preview mode */
    .overtype-container[data-mode="preview"] .syntax-marker {
      display: none !important;
    }
    
    /* Hide URL part of links in preview mode - extra specificity */
    .overtype-container[data-mode="preview"] .syntax-marker.url-part,
    .overtype-container[data-mode="preview"] .url-part {
      display: none !important;
    }
    
    /* Hide all syntax markers inside links too */
    .overtype-container[data-mode="preview"] a .syntax-marker {
      display: none !important;
    }

    /* Headers - restore proper sizing in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview h1,
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview h2,
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview h3 {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
      font-weight: 600 !important;
      margin: 0 !important;
      display: block !important;
      line-height: 1 !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview h1 {
      font-size: 2em !important;
      color: var(--preview-h1, var(--preview-h1-default)) !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview h2 {
      font-size: 1.5em !important;
      color: var(--preview-h2, var(--preview-h2-default)) !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview h3 {
      font-size: 1.17em !important;
      color: var(--preview-h3, var(--preview-h3-default)) !important;
    }

    /* Lists - restore list styling in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview ul {
      display: block !important;
      list-style: disc !important;
      padding-left: 2em !important;
      margin: 1em 0 !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview ol {
      display: block !important;
      list-style: decimal !important;
      padding-left: 2em !important;
      margin: 1em 0 !important;
    }
    
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview li {
      display: list-item !important;
      margin: 0 !important;
      padding: 0 !important;
    }

    /* Task list checkboxes - only in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview li.task-list {
      list-style: none !important;
      position: relative !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview li.task-list input[type="checkbox"] {
      margin-right: 0.5em !important;
      cursor: default !important;
      vertical-align: middle !important;
    }

    /* Task list in normal mode - keep syntax visible */
    .overtype-container:not([data-mode="preview"]) .overtype-wrapper .overtype-preview li.task-list {
      list-style: none !important;
    }

    .overtype-container:not([data-mode="preview"]) .overtype-wrapper .overtype-preview li.task-list .syntax-marker {
      color: var(--syntax, #999999) !important;
      font-weight: normal !important;
    }

    /* Links - make clickable in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview a {
      pointer-events: auto !important;
      cursor: pointer !important;
      color: var(--preview-link, var(--preview-link-default)) !important;
      text-decoration: underline !important;
    }

    /* Code blocks - proper pre/code styling in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview pre.code-block {
      background: var(--preview-code-bg, var(--preview-code-bg-default)) !important;
      color: var(--preview-code, var(--preview-code-default)) !important;
      padding: 1.2em !important;
      border-radius: 3px !important;
      overflow-x: auto !important;
      margin: 0 !important;
      display: block !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview pre.code-block code {
      background: transparent !important;
      color: inherit !important;
      padding: 0 !important;
      font-family: ${r} !important;
      font-size: 0.9em !important;
      line-height: 1.4 !important;
    }

    /* Hide old code block lines and fences in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview .code-block-line {
      display: none !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview .code-fence {
      display: none !important;
    }

    /* Blockquotes - enhanced styling in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview .blockquote {
      display: block !important;
      border-left: 4px solid var(--preview-blockquote, var(--preview-blockquote-default)) !important;
      color: var(--preview-blockquote, var(--preview-blockquote-default)) !important;
      padding-left: 1em !important;
      margin: 1em 0 !important;
      font-style: italic !important;
    }

    /* Typography improvements in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview {
      font-family: Georgia, 'Times New Roman', serif !important;
      font-size: 16px !important;
      line-height: 1.8 !important;
      color: var(--preview-text, var(--preview-text-default)) !important;
      background: var(--preview-bg, var(--preview-bg-default)) !important;
    }

    /* Inline code in preview mode - keep monospace */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview code {
      font-family: ${r} !important;
      font-size: 0.9em !important;
      background: var(--preview-code-bg, var(--preview-code-bg-default)) !important;
      color: var(--preview-code, var(--preview-code-default)) !important;
      padding: 0.2em 0.4em !important;
      border-radius: 3px !important;
    }

    /* Strong and em elements in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview strong {
      font-weight: 700 !important;
      color: var(--preview-strong, var(--preview-strong-default)) !important;
    }

    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview em {
      font-style: italic !important;
      color: var(--preview-em, var(--preview-em-default)) !important;
    }

    /* HR in preview mode */
    .overtype-container[data-mode="preview"] .overtype-wrapper .overtype-preview .hr-marker {
      display: block !important;
      border-top: 2px solid var(--preview-hr, var(--preview-hr-default)) !important;
      text-indent: -9999px !important;
      height: 2px !important;
    }

    /* Link Tooltip */
    .overtype-link-tooltip {
      background: #333 !important;
      color: white !important;
      padding: 6px 10px !important;
      border-radius: 16px !important;
      font-size: 12px !important;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif !important;
      display: flex !important;
      visibility: hidden !important;
      pointer-events: none !important;
      z-index: 10000 !important;
      cursor: pointer !important;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3) !important;
      max-width: 300px !important;
      white-space: nowrap !important;
      overflow: hidden !important;
      text-overflow: ellipsis !important;
      position: fixed;
      top: 0;
      left: 0;
    }

    .overtype-link-tooltip.visible {
      visibility: visible !important;
      pointer-events: auto !important;
    }

    ${s}
  `}var Ee={};n(Ee,{applyCustomFormat:()=>gt,default:()=>_t,expandSelection:()=>ht,getActiveFormats:()=>pt,getDebugMode:()=>Fe,hasFormat:()=>mt,insertHeader:()=>P,insertLink:()=>at,preserveSelection:()=>Ge,setDebugMode:()=>Pe,setUndoMethod:()=>Re,toggleBold:()=>nt,toggleBulletList:()=>ot,toggleCode:()=>it,toggleH1:()=>ut,toggleH2:()=>dt,toggleH3:()=>ft,toggleItalic:()=>rt,toggleNumberedList:()=>st,toggleQuote:()=>ct,toggleTaskList:()=>lt});var De=Object.defineProperty,Oe=Object.getOwnPropertySymbols,ke=Object.prototype.hasOwnProperty,Ae=Object.prototype.propertyIsEnumerable,je=(e,t,n)=>t in e?De(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,Me=(e,t)=>{for(var n in t||(t={}))ke.call(t,n)&&je(e,n,t[n]);if(Oe)for(var n of Oe(t))Ae.call(t,n)&&je(e,n,t[n]);return e},E={bold:{prefix:`**`,suffix:`**`,trimFirst:!0},italic:{prefix:`_`,suffix:`_`,trimFirst:!0},code:{prefix:"`",suffix:"`",blockPrefix:"```",blockSuffix:"```"},link:{prefix:`[`,suffix:`](url)`,replaceNext:`url`,scanFor:`https?://`},bulletList:{prefix:`- `,multiline:!0,unorderedList:!0},numberedList:{prefix:`1. `,multiline:!0,orderedList:!0},quote:{prefix:`> `,multiline:!0,surroundWithNewlines:!0},taskList:{prefix:`- [ ] `,multiline:!0,surroundWithNewlines:!0},header1:{prefix:`# `},header2:{prefix:`## `},header3:{prefix:`### `},header4:{prefix:`#### `},header5:{prefix:`##### `},header6:{prefix:`###### `}};function Ne(){return{prefix:``,suffix:``,blockPrefix:``,blockSuffix:``,multiline:!1,replaceNext:``,prefixSpace:!1,scanFor:``,surroundWithNewlines:!1,orderedList:!1,unorderedList:!1,trimFirst:!1}}function D(e){return Me(Me({},Ne()),e)}var O=!1;function Pe(e){O=e}function Fe(){return O}function k(e,t,n){O&&(console.group(`\u{1F50D} ${e}`),console.log(t),n&&console.log(`Data:`,n),console.groupEnd())}function Ie(e,t){if(!O)return;let n=e.value.slice(e.selectionStart,e.selectionEnd);console.group(`\u{1F4CD} Selection: ${t}`),console.log(`Position:`,`${e.selectionStart}-${e.selectionEnd}`),console.log(`Selected text:`,JSON.stringify(n)),console.log(`Length:`,n.length);let r=e.value.slice(Math.max(0,e.selectionStart-10),e.selectionStart),i=e.value.slice(e.selectionEnd,Math.min(e.value.length,e.selectionEnd+10));console.log(`Context:`,JSON.stringify(r)+`[SELECTION]`+JSON.stringify(i)),console.groupEnd()}function Le(e){O&&(console.group(`📝 Result`),console.log(`Text to insert:`,JSON.stringify(e.text)),console.log(`New selection:`,`${e.selectionStart}-${e.selectionEnd}`),console.groupEnd())}var A=null;function j(e,{text:t,selectionStart:n,selectionEnd:r}){let i=Fe();i&&(console.group(`🔧 insertText`),console.log(`Current selection:`,`${e.selectionStart}-${e.selectionEnd}`),console.log(`Text to insert:`,JSON.stringify(t)),console.log(`New selection to set:`,n,`-`,r)),e.focus();let a=e.selectionStart,o=e.selectionEnd,s=e.value.slice(0,a),c=e.value.slice(o);i&&(console.log(`Before text (last 20):`,JSON.stringify(s.slice(-20))),console.log(`After text (first 20):`,JSON.stringify(c.slice(0,20))),console.log(`Selected text being replaced:`,JSON.stringify(e.value.slice(a,o))));let l=e.value,u=a!==o;if(A===null||A===!0){e.contentEditable=`true`;try{A=document.execCommand(`insertText`,!1,t),i&&console.log(`execCommand returned:`,A,`for text with`,t.split(`
`).length,`lines`)}catch(e){A=!1,i&&console.log(`execCommand threw error:`,e)}e.contentEditable=`false`}if(i&&(console.log(`canInsertText before:`,A),console.log(`execCommand result:`,A)),A){let n=s+t+c,r=e.value;i&&(console.log(`Expected length:`,n.length),console.log(`Actual length:`,r.length)),r!==n&&i&&(console.log(`execCommand changed the value but not as expected`),console.log(`Expected:`,JSON.stringify(n.slice(0,100))),console.log(`Actual:`,JSON.stringify(r.slice(0,100))))}if(!A)if(i&&console.log(`Using manual insertion`),e.value===l){i&&console.log(`Value unchanged, doing manual replacement`);try{document.execCommand(`ms-beginUndoUnit`)}catch(e){}e.value=s+t+c;try{document.execCommand(`ms-endUndoUnit`)}catch(e){}e.dispatchEvent(new CustomEvent(`input`,{bubbles:!0,cancelable:!0}))}else i&&console.log(`Value was changed by execCommand, skipping manual insertion`);i&&console.log(`Setting selection range:`,n,r),n!=null&&r!=null?e.setSelectionRange(n,r):e.setSelectionRange(a,e.selectionEnd),i&&(console.log(`Final value length:`,e.value.length),console.groupEnd())}function Re(e){switch(e){case`native`:A=!0;break;case`manual`:A=!1;break;case`auto`:A=null;break}}function ze(e){return e.trim().split(`
`).length>1}function Be(e,t){let n=t;for(;e[n]&&e[n-1]!=null&&!e[n-1].match(/\s/);)n--;return n}function Ve(e,t,n){let r=t,i=n?/\n/:/\s/;for(;e[r]&&!e[r].match(i);)r++;return r}function He(e){let t=e.value.split(`
`),n=0;for(let r=0;r<t.length;r++){let i=t[r].length+1;e.selectionStart>=n&&e.selectionStart<n+i&&(e.selectionStart=n),e.selectionEnd>=n&&e.selectionEnd<n+i&&(r===t.length-1?e.selectionEnd=Math.min(n+t[r].length,e.value.length):e.selectionEnd=n+i-1),n+=i}}function Ue(e,t,n,r=!1){if(e.selectionStart===e.selectionEnd)e.selectionStart=Be(e.value,e.selectionStart),e.selectionEnd=Ve(e.value,e.selectionEnd,r);else{let r=e.selectionStart-t.length,i=e.selectionEnd+n.length,a=e.value.slice(r,e.selectionStart)===t,o=e.value.slice(e.selectionEnd,i)===n;a&&o&&(e.selectionStart=r,e.selectionEnd=i)}return e.value.slice(e.selectionStart,e.selectionEnd)}function We(e){let t=e.value.slice(0,e.selectionStart),n=e.value.slice(e.selectionEnd),r=t.match(/\n*$/),i=n.match(/^\n*/),a=r?r[0].length:0,o=i?i[0].length:0,s=``,c=``;return t.match(/\S/)&&a<2&&(s=`
`.repeat(2-a)),n.match(/\S/)&&o<2&&(c=`
`.repeat(2-o)),{newlinesToAppend:s,newlinesToPrepend:c}}function Ge(e,t){let n=e.selectionStart,r=e.selectionEnd,i=e.scrollTop;t(),e.selectionStart=n,e.selectionEnd=r,e.scrollTop=i}function Ke(e,t,n={}){let r=e.selectionStart,i=e.selectionEnd,a=r===i,o=e.value,s=r;for(;s>0&&o[s-1]!==`
`;)s--;if(a){let t=r;for(;t<o.length&&o[t]!==`
`;)t++;e.selectionStart=s,e.selectionEnd=t}else He(e);let c=t(e);if(n.adjustSelection){let t=e.value.slice(e.selectionStart,e.selectionEnd).startsWith(n.prefix),a=n.adjustSelection(t,r,i,s);c.selectionStart=a.start,c.selectionEnd=a.end}else if(n.prefix){let t=e.value.slice(e.selectionStart,e.selectionEnd).startsWith(n.prefix);a?t?(c.selectionStart=Math.max(r-n.prefix.length,s),c.selectionEnd=c.selectionStart):(c.selectionStart=r+n.prefix.length,c.selectionEnd=c.selectionStart):t?(c.selectionStart=Math.max(r-n.prefix.length,s),c.selectionEnd=Math.max(i-n.prefix.length,s)):(c.selectionStart=r+n.prefix.length,c.selectionEnd=i+n.prefix.length)}return c}function M(e,t){let n,r,{prefix:i,suffix:a,blockPrefix:o,blockSuffix:s,replaceNext:c,prefixSpace:l,scanFor:u,surroundWithNewlines:d,trimFirst:f}=t,p=e.selectionStart,m=e.selectionEnd,h=e.value.slice(e.selectionStart,e.selectionEnd),g=ze(h)&&o&&o.length>0?`${o}
`:i,_=ze(h)&&s&&s.length>0?`
${s}`:a;if(l){let t=e.value[e.selectionStart-1];e.selectionStart!==0&&t!=null&&!t.match(/\s/)&&(g=` ${g}`)}h=Ue(e,g,_,t.multiline);let v=e.selectionStart,y=e.selectionEnd,b=c&&c.length>0&&_.indexOf(c)>-1&&h.length>0;if(d){let t=We(e);n=t.newlinesToAppend,r=t.newlinesToPrepend,g=n+i,_+=r}if(h.startsWith(g)&&h.endsWith(_)){let e=h.slice(g.length,h.length-_.length);if(p===m){let t=p-g.length;t=Math.max(t,v),t=Math.min(t,v+e.length),v=y=t}else y=v+e.length;return{text:e,selectionStart:v,selectionEnd:y}}else if(!b){let e=g+h+_;v=p+g.length,y=m+g.length;let t=h.match(/^\s*|\s*$/g);if(f&&t){let n=t[0]||``,r=t[1]||``;e=n+g+h.trim()+_+r,v+=n.length,y-=r.length}return{text:e,selectionStart:v,selectionEnd:y}}else if(u&&u.length>0&&h.match(u)){_=_.replace(c,h);let e=g+_;return v=y=v+g.length,{text:e,selectionStart:v,selectionEnd:y}}else{let e=g+h+_;return v=v+g.length+h.length+_.indexOf(c),y=v+c.length,{text:e,selectionStart:v,selectionEnd:y}}}function qe(e,t){let{prefix:n,suffix:r,surroundWithNewlines:i}=t,a=e.value.slice(e.selectionStart,e.selectionEnd),o=e.selectionStart,s=e.selectionEnd,c=a.split(`
`);if(c.every(e=>e.startsWith(n)&&(!r||e.endsWith(r))))a=c.map(e=>{let t=e.slice(n.length);return r&&(t=t.slice(0,t.length-r.length)),t}).join(`
`),s=o+a.length;else if(a=c.map(e=>n+e+(r||``)).join(`
`),i){let{newlinesToAppend:t,newlinesToPrepend:n}=We(e);o+=t.length,s=o+a.length,a=t+a+n}return{text:a,selectionStart:o,selectionEnd:s}}function Je(e){let t=e.split(`
`),n=/^\d+\.\s+/,r=t.every(e=>n.test(e)),i=t;return r&&(i=t.map(e=>e.replace(n,``))),{text:i.join(`
`),processed:r}}function Ye(e){let t=e.split(`
`),n=`- `,r=t.every(e=>e.startsWith(`- `)),i=t;return r&&(i=t.map(e=>e.slice(2))),{text:i.join(`
`),processed:r}}function N(e,t){return t?`- `:`${e+1}. `}function Xe(e,t){let n,r,i;return e.orderedList?(n=Je(t),r=Ye(n.text),i=r.text):(n=Ye(t),r=Je(n.text),i=r.text),[n,r,i]}function Ze(e,t){let n=e.selectionStart===e.selectionEnd,r=e.selectionStart,i=e.selectionEnd;He(e);let[a,o,s]=Xe(t,e.value.slice(e.selectionStart,e.selectionEnd)),c=s.split(`
`).map((e,n)=>`${N(n,t.unorderedList)}${e}`),l=c.reduce((e,n,r)=>e+N(r,t.unorderedList).length,0),u=c.reduce((e,n,r)=>e+N(r,!t.unorderedList).length,0);if(a.processed)return n?(r=Math.max(r-N(0,t.unorderedList).length,0),i=r):(r=e.selectionStart,i=e.selectionEnd-l),{text:s,selectionStart:r,selectionEnd:i};let{newlinesToAppend:d,newlinesToPrepend:f}=We(e),p=d+c.join(`
`)+f;return n?(r=Math.max(r+N(0,t.unorderedList).length+d.length,0),i=r):o.processed?(r=Math.max(e.selectionStart+d.length,0),i=e.selectionEnd+d.length+l-u):(r=Math.max(e.selectionStart+d.length,0),i=e.selectionEnd+d.length+l),{text:p,selectionStart:r,selectionEnd:i}}function Qe(e,t){j(e,Ke(e,e=>Ze(e,t),{adjustSelection:(n,r,i,a)=>{let o=e.value.slice(a,e.selectionEnd),s=/^\d+\.\s+/,c=/^- /,l=s.test(o),u=c.test(o),d=t.orderedList&&l||t.unorderedList&&u;if(r===i)if(d){let e=o.match(t.orderedList?s:c),n=e?e[0].length:0;return{start:Math.max(r-n,a),end:Math.max(r-n,a)}}else if(l||u){let e=o.match(l?s:c),n=e?e[0].length:0,i=(t.unorderedList?2:3)-n;return{start:r+i,end:r+i}}else{let e=t.unorderedList?2:3;return{start:r+e,end:r+e}}else if(d){let e=o.match(t.orderedList?s:c),n=e?e[0].length:0;return{start:Math.max(r-n,a),end:Math.max(i-n,a)}}else if(l||u){let e=o.match(l?s:c),n=e?e[0].length:0,a=(t.unorderedList?2:3)-n;return{start:r+a,end:i+a}}else{let e=t.unorderedList?2:3;return{start:r+e,end:i+e}}}}))}function $e(e){if(!e)return[];let t=[],{selectionStart:n,selectionEnd:r,value:i}=e,a=i.split(`
`),o=0,s=``;for(let e of a){if(n>=o&&n<=o+e.length){s=e;break}o+=e.length+1}s.startsWith(`- `)&&(s.startsWith(`- [ ] `)||s.startsWith(`- [x] `)?t.push(`task-list`):t.push(`bullet-list`)),/^\d+\.\s/.test(s)&&t.push(`numbered-list`),s.startsWith(`> `)&&t.push(`quote`),s.startsWith(`# `)&&t.push(`header`),s.startsWith(`## `)&&t.push(`header-2`),s.startsWith(`### `)&&t.push(`header-3`);let c=Math.max(0,n-10),l=Math.min(i.length,r+10),u=i.slice(c,l);if(u.includes(`**`)){let e=i.slice(Math.max(0,n-100),n),a=i.slice(r,Math.min(i.length,r+100)),o=e.lastIndexOf(`**`),s=a.indexOf(`**`);o!==-1&&s!==-1&&t.push(`bold`)}if(u.includes(`_`)){let e=i.slice(Math.max(0,n-100),n),a=i.slice(r,Math.min(i.length,r+100)),o=e.lastIndexOf(`_`),s=a.indexOf(`_`);o!==-1&&s!==-1&&t.push(`italic`)}if(u.includes("`")){let e=i.slice(Math.max(0,n-100),n),a=i.slice(r,Math.min(i.length,r+100));e.includes("`")&&a.includes("`")&&t.push(`code`)}if(u.includes(`[`)&&u.includes(`]`)){let e=i.slice(Math.max(0,n-100),n),a=i.slice(r,Math.min(i.length,r+100)),o=e.lastIndexOf(`[`),s=a.indexOf(`]`);o!==-1&&s!==-1&&i.slice(r+s+1,r+s+10).startsWith(`(`)&&t.push(`link`)}return t}function et(e,t){return $e(e).includes(t)}function tt(e,t={}){if(!e)return;let{toWord:n,toLine:r,toFormat:i}=t,{selectionStart:a,selectionEnd:o,value:s}=e;if(r){let t=s.split(`
`),n=0,r=0,i=0;for(let e of t){if(a>=i&&a<=i+e.length){n=i,r=i+e.length;break}i+=e.length+1}e.selectionStart=n,e.selectionEnd=r}else if(n&&a===o){let t=a,n=o;for(;t>0&&!/\s/.test(s[t-1]);)t--;for(;n<s.length&&!/\s/.test(s[n]);)n++;e.selectionStart=t,e.selectionEnd=n}}function nt(e){if(!e||e.disabled||e.readOnly)return;k(`toggleBold`,`Starting`),Ie(e,`Before`);let t=M(e,D(E.bold));Le(t),j(e,t),Ie(e,`After`)}function rt(e){!e||e.disabled||e.readOnly||j(e,M(e,D(E.italic)))}function it(e){!e||e.disabled||e.readOnly||j(e,M(e,D(E.code)))}function at(e,t={}){if(!e||e.disabled||e.readOnly)return;let n=e.value.slice(e.selectionStart,e.selectionEnd),r=D(E.link);if(n&&n.match(/^https?:\/\//)&&!t.url?(r.suffix=`](${n})`,r.replaceNext=``):t.url&&(r.suffix=`](${t.url})`,r.replaceNext=``),t.text&&!n){let n=e.selectionStart;e.value=e.value.slice(0,n)+t.text+e.value.slice(n),e.selectionStart=n,e.selectionEnd=n+t.text.length}j(e,M(e,r))}function ot(e){!e||e.disabled||e.readOnly||Qe(e,D(E.bulletList))}function st(e){!e||e.disabled||e.readOnly||Qe(e,D(E.numberedList))}function ct(e){if(!e||e.disabled||e.readOnly)return;k(`toggleQuote`,`Starting`),Ie(e,`Initial`);let t=D(E.quote),n=Ke(e,e=>qe(e,t),{prefix:t.prefix});Le(n),j(e,n),Ie(e,`Final`)}function lt(e){if(!e||e.disabled||e.readOnly)return;let t=D(E.taskList);j(e,Ke(e,e=>qe(e,t),{prefix:t.prefix}))}function P(e,t=1,n=!1){if(!e||e.disabled||e.readOnly)return;(t<1||t>6)&&(t=1),k(`insertHeader`,`============ START ============`),k(`insertHeader`,`Level: ${t}, Toggle: ${n}`),k(`insertHeader`,`Initial cursor: ${e.selectionStart}-${e.selectionEnd}`);let r=D(E[`header${t===1?`1`:t}`]||E.header1);k(`insertHeader`,`Style prefix: "${r.prefix}"`);let i=e.value,a=e.selectionStart,o=e.selectionEnd,s=a;for(;s>0&&i[s-1]!==`
`;)s--;let c=o;for(;c<i.length&&i[c]!==`
`;)c++;let l=i.slice(s,c);k(`insertHeader`,`Current line (before): "${l}"`);let u=l.match(/^(#{1,6})\s*/),d=u?u[1].length:0,f=u?u[0].length:0;k(`insertHeader`,`Existing header check:`),k(`insertHeader`,`  - Match: ${u?`"${u[0]}"`:`none`}`),k(`insertHeader`,`  - Existing level: ${d}`),k(`insertHeader`,`  - Existing prefix length: ${f}`),k(`insertHeader`,`  - Target level: ${t}`);let p=n&&d===t;k(`insertHeader`,`Should toggle OFF: ${p} (toggle=${n}, existingLevel=${d}, level=${t})`);let m=Ke(e,e=>{let n=e.value.slice(e.selectionStart,e.selectionEnd);k(`insertHeader`,`Line in operation: "${n}"`);let i=n.replace(/^#{1,6}\s*/,``);k(`insertHeader`,`Cleaned line: "${i}"`);let a;return p?(k(`insertHeader`,`ACTION: Toggling OFF - removing header`),a=i):d>0?(k(`insertHeader`,`ACTION: Replacing H${d} with H${t}`),a=r.prefix+i):(k(`insertHeader`,`ACTION: Adding new header`),a=r.prefix+i),k(`insertHeader`,`New line: "${a}"`),{text:a,selectionStart:e.selectionStart,selectionEnd:e.selectionEnd}},{prefix:r.prefix,adjustSelection:(e,t,n,i)=>{if(k(`insertHeader`,`Adjusting selection:`),k(`insertHeader`,`  - isRemoving param: ${e}`),k(`insertHeader`,`  - shouldToggleOff: ${p}`),k(`insertHeader`,`  - selStart: ${t}, selEnd: ${n}`),k(`insertHeader`,`  - lineStartPos: ${i}`),p){let e=Math.max(t-f,i);return k(`insertHeader`,`  - Removing header, adjusting by -${f}`),{start:e,end:t===n?e:Math.max(n-f,i)}}else if(f>0){let e=r.prefix.length-f;return k(`insertHeader`,`  - Replacing header, adjusting by ${e}`),{start:t+e,end:n+e}}else return k(`insertHeader`,`  - Adding header, adjusting by +${r.prefix.length}`),{start:t+r.prefix.length,end:n+r.prefix.length}}});k(`insertHeader`,`Final result: text="${m.text}", cursor=${m.selectionStart}-${m.selectionEnd}`),k(`insertHeader`,`============ END ============`),j(e,m)}function ut(e){P(e,1,!0)}function dt(e){P(e,2,!0)}function ft(e){P(e,3,!0)}function pt(e){return $e(e)}function mt(e,t){return et(e,t)}function ht(e,t={}){tt(e,t)}function gt(e,t){if(!e||e.disabled||e.readOnly)return;let n=D(t),r;r=n.multiline&&ze(e.value.slice(e.selectionStart,e.selectionEnd))?qe(e,n):M(e,n),j(e,r)}var _t={toggleBold:nt,toggleItalic:rt,toggleCode:it,insertLink:at,toggleBulletList:ot,toggleNumberedList:st,toggleQuote:ct,toggleTaskList:lt,insertHeader:P,toggleH1:ut,toggleH2:dt,toggleH3:ft,getActiveFormats:pt,hasFormat:mt,expandSelection:ht,applyCustomFormat:gt,preserveSelection:Ge,setUndoMethod:Re,setDebugMode:Pe,getDebugMode:Fe},Toolbar=class{constructor(e,t={}){this.editor=e,this.container=null,this.buttons={},this.currentItemIndex=0,this.handleDocumentClick=null,this.activeDropdown=null,this.activeDropdownButton=null,this.toolbarButtons=t.toolbarButtons||[]}create(){this.container=document.createElement(`div`),this.container.className=`overtype-toolbar`,this.editor._markChrome(this.container),this.container.id=this.getInstanceElementId(`toolbar`),this.container.setAttribute(`role`,`toolbar`),this.container.setAttribute(`aria-label`,`Formatting toolbar`),this.container.setAttribute(`aria-controls`,this.editor.textarea.id),this.toolbarButtons.forEach(e=>{if(e.name===`separator`){let e=this.createSeparator();this.container.appendChild(e)}else{let t=this.createButton(e);this.buttons[e.name]=t,this.container.appendChild(t)}}),this.setupRovingTabIndex(),this.updateButtonStates(),this.editor.container.insertBefore(this.container,this.editor.wrapper)}getInstanceElementId(e){return`overtype-${this.editor.instanceId}-${e}`}setupRovingTabIndex(){this.getToolbarItems().length!==0&&(this.currentItemIndex=this.getValidItemIndex(this.currentItemIndex),this.updateTabIndexes(),this.container.addEventListener(`keydown`,e=>{this.onToolbarKeydown(e)}),this.container.addEventListener(`focusin`,e=>{this.onToolbarFocusin(e)}))}getToolbarItems(){return this.container?Array.from(this.container.querySelectorAll(`.overtype-toolbar-button`)):[]}onToolbarKeydown(e){let t=this.getToolbarItems();if(t.includes(e.target))switch(e.key){case`ArrowRight`:e.preventDefault(),this.focusItem(this.currentItemIndex+1);break;case`ArrowLeft`:e.preventDefault(),this.focusItem(this.currentItemIndex-1);break;case`Home`:e.preventDefault(),this.focusItem(0);break;case`End`:e.preventDefault(),this.focusItem(t.length-1);break}}onToolbarFocusin(e){let t=this.getToolbarItems().indexOf(e.target);t!==-1&&(this.currentItemIndex=t,this.updateTabIndexes())}focusItem(e){let t=this.getToolbarItems();t.length!==0&&(this.currentItemIndex=this.getValidItemIndex(e,t),this.updateTabIndexes(),t[this.currentItemIndex].focus())}getValidItemIndex(e,t=this.getToolbarItems()){let n=t.length;return n===0?0:e<0?n-1:e>=n?0:e}updateTabIndexes(){this.getToolbarItems().forEach((e,t)=>{e.tabIndex=t===this.currentItemIndex?0:-1})}createSeparator(){let e=document.createElement(`div`);return e.className=`overtype-toolbar-separator`,e.setAttribute(`role`,`separator`),e}createButton(e){let t=document.createElement(`button`);return t.className=`overtype-toolbar-button`,t.type=`button`,t.setAttribute(`data-button`,e.name),t.title=e.title||``,t.setAttribute(`aria-label`,e.title||e.name),t.innerHTML=this.sanitizeSVG(e.icon||``),e.name===`viewMode`?(t.classList.add(`has-dropdown`),t.dataset.dropdown=`true`,t.setAttribute(`aria-haspopup`,`menu`),t.setAttribute(`aria-expanded`,`false`),t._clickHandler=e=>{e.preventDefault(),this.toggleViewModeDropdown(t)},t._keydownHandler=e=>{if(![`ArrowDown`,`ArrowUp`,`Enter`,` `].includes(e.key))return;e.preventDefault();let n=e.key===`ArrowUp`?`last`:`current`;this.openViewModeDropdown(t,n)},t.addEventListener(`click`,t._clickHandler),t.addEventListener(`keydown`,t._keydownHandler),t):(t._clickHandler=t=>{t.preventDefault();let n=e.actionId||e.name;this.editor.performAction(n,t)},t.addEventListener(`click`,t._clickHandler),t)}async handleAction(e){if(e&&typeof e==`object`&&typeof e.action==`function`){this.editor.textarea.focus();try{return await e.action({editor:this.editor,getValue:()=>this.editor.getValue(),setValue:e=>this.editor.setValue(e),event:null}),!0}catch(t){return console.error(`Action "${e.name}" error:`,t),this.editor.wrapper.dispatchEvent(new CustomEvent(`button-error`,{detail:{buttonName:e.name,error:t}})),!1}}return typeof e==`string`?this.editor.performAction(e,null):!1}sanitizeSVG(e){return typeof e==`string`?e.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,``).replace(/\son\w+\s*=\s*["'][^"']*["']/gi,``).replace(/\son\w+\s*=\s*[^\s>]*/gi,``):``}toggleViewModeDropdown(e){if(this.activeDropdown){this.closeViewModeDropdown(e);return}this.openViewModeDropdown(e)}openViewModeDropdown(e,t=null){this.closeViewModeDropdown(e),e.classList.add(`dropdown-active`);let n=this.createViewModeDropdown(e),r=e.getBoundingClientRect();n.style.position=`absolute`,n.style.top=`${r.bottom+5}px`,n.style.left=`${r.left}px`,document.body.appendChild(n),this.activeDropdown=n,this.activeDropdownButton=e,e.setAttribute(`aria-controls`,n.id),e.setAttribute(`aria-expanded`,`true`),this.handleDocumentClick=t=>{!n.contains(t.target)&&!e.contains(t.target)&&this.closeViewModeDropdown(e)},setTimeout(()=>{document.addEventListener(`click`,this.handleDocumentClick)},0),t&&this.focusViewModeMenuItem(n,t)}closeViewModeDropdown(e=this.activeDropdownButton,t=!1){this.activeDropdown&&(this.activeDropdown.remove(),this.activeDropdown=null),e&&(e.classList.remove(`dropdown-active`),e.setAttribute(`aria-expanded`,`false`)),this.handleDocumentClick&&(document.removeEventListener(`click`,this.handleDocumentClick),this.handleDocumentClick=null),this.activeDropdownButton=null,t&&e&&e.focus()}createViewModeDropdown(e){let t=document.createElement(`div`);t.className=`overtype-dropdown-menu`,this.editor._markChrome(t),t.id=this.getInstanceElementId(`toolbar-view-mode-menu`),t.setAttribute(`role`,`menu`),t.setAttribute(`aria-label`,`View mode`),t.addEventListener(`keydown`,t=>{this.onViewModeMenuKeydown(t,e)});let n=[{id:`normal`,label:`Normal Edit`,icon:`✓`},{id:`plain`,label:`Plain Textarea`,icon:`✓`},{id:`preview`,label:`Preview Mode`,icon:`✓`}],r=this.editor.container.dataset.mode||`normal`;return n.forEach(n=>{let i=document.createElement(`button`);if(i.className=`overtype-dropdown-item`,i.type=`button`,i.tabIndex=-1,i.setAttribute(`role`,`menuitemradio`),i.setAttribute(`aria-checked`,String(n.id===r)),i.textContent=n.label,n.id===r){i.classList.add(`active`);let e=document.createElement(`span`);e.className=`overtype-dropdown-icon`,e.setAttribute(`aria-hidden`,`true`),e.textContent=n.icon,i.prepend(e)}i.addEventListener(`click`,t=>{switch(t.preventDefault(),n.id){case`plain`:this.editor.showPlainTextarea();break;case`preview`:this.editor.showPreviewMode();break;default:this.editor.showNormalEditMode();break}this.closeViewModeDropdown(e,!0)}),t.appendChild(i)}),t}onViewModeMenuKeydown(e,t){let n=this.getViewModeMenuItems().indexOf(e.target);if(n!==-1)switch(e.key){case`ArrowDown`:e.preventDefault(),this.focusViewModeMenuItem(this.activeDropdown,n+1);break;case`ArrowUp`:e.preventDefault(),this.focusViewModeMenuItem(this.activeDropdown,n-1);break;case`Home`:e.preventDefault(),this.focusViewModeMenuItem(this.activeDropdown,`first`);break;case`End`:e.preventDefault(),this.focusViewModeMenuItem(this.activeDropdown,`last`);break;case`Escape`:e.preventDefault(),this.closeViewModeDropdown(t,!0);break}}focusViewModeMenuItem(e,t){let n=this.getViewModeMenuItems(e);if(n.length===0)return;let r=t;t===`first`?r=0:t===`last`?r=n.length-1:t===`current`&&(r=n.findIndex(e=>e.getAttribute(`aria-checked`)===`true`)),r<0&&(r=n.length-1),r>=n.length&&(r=0),n[r].focus()}getViewModeMenuItems(e=this.activeDropdown){return e?Array.from(e.querySelectorAll(`[role="menuitemradio"]`)):[]}updateButtonStates(){var e;try{let t=((e=pt)==null?void 0:e(this.editor.textarea,this.editor.textarea.selectionStart))||[];Object.entries(this.buttons).forEach(([e,n])=>{if(e===`viewMode`)return;let r=this.toolbarButtons.find(t=>t.name===e);if(!(r!=null&&r.isActive))return;let i=!!r.isActive({editor:this.editor,activeFormats:t});n.classList.toggle(`active`,i),n.setAttribute(`aria-pressed`,i.toString())})}catch(e){}}show(){this.container&&this.container.classList.remove(`overtype-toolbar-hidden`)}hide(){this.container&&this.container.classList.add(`overtype-toolbar-hidden`)}destroy(){this.container&&(this.activeDropdown?this.closeViewModeDropdown():this.handleDocumentClick&&(document.removeEventListener(`click`,this.handleDocumentClick),this.handleDocumentClick=null),Object.values(this.buttons).forEach(e=>{e._clickHandler&&(e.removeEventListener(`click`,e._clickHandler),delete e._clickHandler),e._keydownHandler&&(e.removeEventListener(`keydown`,e._keydownHandler),delete e._keydownHandler)}),this.container.remove(),this.container=null,this.buttons={})}},vt=Math.min,F=Math.max,yt=Math.round,I=e=>({x:e,y:e}),bt={left:`right`,right:`left`,bottom:`top`,top:`bottom`},xt={start:`end`,end:`start`};function St(e,t,n){return F(e,vt(t,n))}function Ct(e,t){return typeof e==`function`?e(t):e}function L(e){return e.split(`-`)[0]}function wt(e){return e.split(`-`)[1]}function Tt(e){return e===`x`?`y`:`x`}function Et(e){return e===`y`?`height`:`width`}var Dt=/* @__PURE__ */ new Set([`top`,`bottom`]);function R(e){return Dt.has(L(e))?`y`:`x`}function Ot(e){return Tt(R(e))}function kt(e,t,n){n===void 0&&(n=!1);let r=wt(e),i=Ot(e),a=Et(i),o=i===`x`?r===(n?`end`:`start`)?`right`:`left`:r===`start`?`bottom`:`top`;return t.reference[a]>t.floating[a]&&(o=Rt(o)),[o,Rt(o)]}function At(e){let t=Rt(e);return[jt(e),t,jt(t)]}function jt(e){return e.replace(/start|end/g,e=>xt[e])}var Mt=[`left`,`right`],Nt=[`right`,`left`],Pt=[`top`,`bottom`],Ft=[`bottom`,`top`];function It(e,t,n){switch(e){case`top`:case`bottom`:return n?t?Nt:Mt:t?Mt:Nt;case`left`:case`right`:return t?Pt:Ft;default:return[]}}function Lt(e,t,n,r){let i=wt(e),a=It(L(e),n===`start`,r);return i&&(a=a.map(e=>e+`-`+i),t&&(a=a.concat(a.map(jt)))),a}function Rt(e){return e.replace(/left|right|bottom|top/g,e=>bt[e])}function zt(e){return{top:0,right:0,bottom:0,left:0,...e}}function Bt(e){return typeof e==`number`?{top:e,right:e,bottom:e,left:e}:zt(e)}function Vt(e){let{x:t,y:n,width:r,height:i}=e;return{width:r,height:i,top:n,left:t,right:t+r,bottom:n+i,x:t,y:n}}function Ht(e,t,n){let{reference:r,floating:i}=e,a=R(t),o=Ot(t),s=Et(o),c=L(t),l=a===`y`,u=r.x+r.width/2-i.width/2,d=r.y+r.height/2-i.height/2,f=r[s]/2-i[s]/2,p;switch(c){case`top`:p={x:u,y:r.y-i.height};break;case`bottom`:p={x:u,y:r.y+r.height};break;case`right`:p={x:r.x+r.width,y:d};break;case`left`:p={x:r.x-i.width,y:d};break;default:p={x:r.x,y:r.y}}switch(wt(t)){case`start`:p[o]-=f*(n&&l?-1:1);break;case`end`:p[o]+=f*(n&&l?-1:1);break}return p}async function Ut(e,t){var n;t===void 0&&(t={});let{x:r,y:i,platform:a,rects:o,elements:s,strategy:c}=e,{boundary:l=`clippingAncestors`,rootBoundary:u=`viewport`,elementContext:d=`floating`,altBoundary:f=!1,padding:p=0}=Ct(t,e),m=Bt(p),h=s[f?d===`floating`?`reference`:`floating`:d],g=Vt(await a.getClippingRect({element:(n=await(a.isElement==null?void 0:a.isElement(h)))==null||n?h:h.contextElement||await(a.getDocumentElement==null?void 0:a.getDocumentElement(s.floating)),boundary:l,rootBoundary:u,strategy:c})),_=d===`floating`?{x:r,y:i,width:o.floating.width,height:o.floating.height}:o.reference,v=await(a.getOffsetParent==null?void 0:a.getOffsetParent(s.floating)),y=await(a.isElement==null?void 0:a.isElement(v))&&await(a.getScale==null?void 0:a.getScale(v))||{x:1,y:1},b=Vt(a.convertOffsetParentRelativeRectToViewportRelativeRect?await a.convertOffsetParentRelativeRectToViewportRelativeRect({elements:s,rect:_,offsetParent:v,strategy:c}):_);return{top:(g.top-b.top+m.top)/y.y,bottom:(b.bottom-g.bottom+m.bottom)/y.y,left:(g.left-b.left+m.left)/y.x,right:(b.right-g.right+m.right)/y.x}}var Wt=async(e,t,n)=>{let{placement:r=`bottom`,strategy:i=`absolute`,middleware:a=[],platform:o}=n,s=a.filter(Boolean),c=await(o.isRTL==null?void 0:o.isRTL(t)),l=await o.getElementRects({reference:e,floating:t,strategy:i}),{x:u,y:d}=Ht(l,r,c),f=r,p={},m=0;for(let n=0;n<s.length;n++){var h;let{name:a,fn:g}=s[n],{x:_,y:v,data:y,reset:b}=await g({x:u,y:d,initialPlacement:r,placement:f,strategy:i,middlewareData:p,rects:l,platform:{...o,detectOverflow:(h=o.detectOverflow)==null?Ut:h},elements:{reference:e,floating:t}});u=_==null?u:_,d=v==null?d:v,p={...p,[a]:{...p[a],...y}},b&&m<=50&&(m++,typeof b==`object`&&(b.placement&&(f=b.placement),b.rects&&(l=b.rects===!0?await o.getElementRects({reference:e,floating:t,strategy:i}):b.rects),{x:u,y:d}=Ht(l,f,c)),n=-1)}return{x:u,y:d,placement:f,strategy:i,middlewareData:p}},Gt=function(e){return e===void 0&&(e={}),{name:`flip`,options:e,async fn(t){var n,r;let{placement:i,middlewareData:a,rects:o,initialPlacement:s,platform:c,elements:l}=t,{mainAxis:u=!0,crossAxis:d=!0,fallbackPlacements:f,fallbackStrategy:p=`bestFit`,fallbackAxisSideDirection:m=`none`,flipAlignment:h=!0,...g}=Ct(e,t);if((n=a.arrow)!=null&&n.alignmentOffset)return{};let _=L(i),v=R(s),y=L(s)===s,b=await(c.isRTL==null?void 0:c.isRTL(l.floating)),ee=f||(y||!h?[Rt(s)]:At(s)),te=m!==`none`;!f&&te&&ee.push(...Lt(s,h,m,b));let ne=[s,...ee],re=await c.detectOverflow(t,g),ie=[],x=((r=a.flip)==null?void 0:r.overflows)||[];if(u&&ie.push(re[_]),d){let e=kt(i,o,b);ie.push(re[e[0]],re[e[1]])}if(x=[...x,{placement:i,overflows:ie}],!ie.every(e=>e<=0)){var ae,oe;let e=(((ae=a.flip)==null?void 0:ae.index)||0)+1,t=ne[e];if(t&&(!(d===`alignment`&&v!==R(t))||x.every(e=>R(e.placement)===v?e.overflows[0]>0:!0)))return{data:{index:e,overflows:x},reset:{placement:t}};let n=(oe=x.filter(e=>e.overflows[0]<=0).sort((e,t)=>e.overflows[1]-t.overflows[1])[0])==null?void 0:oe.placement;if(!n)switch(p){case`bestFit`:{var se;let e=(se=x.filter(e=>{if(te){let t=R(e.placement);return t===v||t===`y`}return!0}).map(e=>[e.placement,e.overflows.filter(e=>e>0).reduce((e,t)=>e+t,0)]).sort((e,t)=>e[1]-t[1])[0])==null?void 0:se[0];e&&(n=e);break}case`initialPlacement`:n=s;break}if(i!==n)return{reset:{placement:n}}}return{}}}},Kt=/* @__PURE__ */ new Set([`left`,`top`]);async function qt(e,t){let{placement:n,platform:r,elements:i}=e,a=await(r.isRTL==null?void 0:r.isRTL(i.floating)),o=L(n),s=wt(n),c=R(n)===`y`,l=Kt.has(o)?-1:1,u=a&&c?-1:1,d=Ct(t,e),{mainAxis:f,crossAxis:p,alignmentAxis:m}=typeof d==`number`?{mainAxis:d,crossAxis:0,alignmentAxis:null}:{mainAxis:d.mainAxis||0,crossAxis:d.crossAxis||0,alignmentAxis:d.alignmentAxis};return s&&typeof m==`number`&&(p=s===`end`?m*-1:m),c?{x:p*u,y:f*l}:{x:f*l,y:p*u}}var Jt=function(e){return e===void 0&&(e=0),{name:`offset`,options:e,async fn(t){var n,r;let{x:i,y:a,placement:o,middlewareData:s}=t,c=await qt(t,e);return o===((n=s.offset)==null?void 0:n.placement)&&(r=s.arrow)!=null&&r.alignmentOffset?{}:{x:i+c.x,y:a+c.y,data:{...c,placement:o}}}}},Yt=function(e){return e===void 0&&(e={}),{name:`shift`,options:e,async fn(t){let{x:n,y:r,placement:i,platform:a}=t,{mainAxis:o=!0,crossAxis:s=!1,limiter:c={fn:e=>{let{x:t,y:n}=e;return{x:t,y:n}}},...l}=Ct(e,t),u={x:n,y:r},d=await a.detectOverflow(t,l),f=R(L(i)),p=Tt(f),m=u[p],h=u[f];if(o){let e=p===`y`?`top`:`left`,t=p===`y`?`bottom`:`right`,n=m+d[e],r=m-d[t];m=St(n,m,r)}if(s){let e=f===`y`?`top`:`left`,t=f===`y`?`bottom`:`right`,n=h+d[e],r=h-d[t];h=St(n,h,r)}let g=c.fn({...t,[p]:m,[f]:h});return{...g,data:{x:g.x-n,y:g.y-r,enabled:{[p]:o,[f]:s}}}}}};function Xt(){return typeof window<`u`}function z(e){return Zt(e)?(e.nodeName||``).toLowerCase():`#document`}function B(e){var t;return(e==null||(t=e.ownerDocument)==null?void 0:t.defaultView)||window}function V(e){var t;return(t=(Zt(e)?e.ownerDocument:e.document)||window.document)==null?void 0:t.documentElement}function Zt(e){return Xt()?e instanceof Node||e instanceof B(e).Node:!1}function H(e){return Xt()?e instanceof Element||e instanceof B(e).Element:!1}function U(e){return Xt()?e instanceof HTMLElement||e instanceof B(e).HTMLElement:!1}function Qt(e){return!Xt()||typeof ShadowRoot>`u`?!1:e instanceof ShadowRoot||e instanceof B(e).ShadowRoot}var $t=/* @__PURE__ */ new Set([`inline`,`contents`]);function W(e){let{overflow:t,overflowX:n,overflowY:r,display:i}=K(e);return/auto|scroll|overlay|hidden|clip/.test(t+r+n)&&!$t.has(i)}var en=/* @__PURE__ */ new Set([`table`,`td`,`th`]);function tn(e){return en.has(z(e))}var nn=[`:popover-open`,`:modal`];function rn(e){return nn.some(t=>{try{return e.matches(t)}catch(e){return!1}})}var an=[`transform`,`translate`,`scale`,`rotate`,`perspective`],on=[`transform`,`translate`,`scale`,`rotate`,`perspective`,`filter`],sn=[`paint`,`layout`,`strict`,`content`];function cn(e){let t=un(),n=H(e)?K(e):e;return an.some(e=>n[e]?n[e]!==`none`:!1)||(n.containerType?n.containerType!==`normal`:!1)||!t&&(n.backdropFilter?n.backdropFilter!==`none`:!1)||!t&&(n.filter?n.filter!==`none`:!1)||on.some(e=>(n.willChange||``).includes(e))||sn.some(e=>(n.contain||``).includes(e))}function ln(e){let t=q(e);for(;U(t)&&!G(t);){if(cn(t))return t;if(rn(t))return null;t=q(t)}return null}function un(){return typeof CSS>`u`||!CSS.supports?!1:CSS.supports(`-webkit-backdrop-filter`,`none`)}var dn=/* @__PURE__ */ new Set([`html`,`body`,`#document`]);function G(e){return dn.has(z(e))}function K(e){return B(e).getComputedStyle(e)}function fn(e){return H(e)?{scrollLeft:e.scrollLeft,scrollTop:e.scrollTop}:{scrollLeft:e.scrollX,scrollTop:e.scrollY}}function q(e){if(z(e)===`html`)return e;let t=e.assignedSlot||e.parentNode||Qt(e)&&e.host||V(e);return Qt(t)?t.host:t}function pn(e){let t=q(e);return G(t)?e.ownerDocument?e.ownerDocument.body:e.body:U(t)&&W(t)?t:pn(t)}function mn(e,t,n){var r;t===void 0&&(t=[]),n===void 0&&(n=!0);let i=pn(e),a=i===((r=e.ownerDocument)==null?void 0:r.body),o=B(i);if(a){let e=hn(o);return t.concat(o,o.visualViewport||[],W(i)?i:[],e&&n?mn(e):[])}return t.concat(i,mn(i,[],n))}function hn(e){return e.parent&&Object.getPrototypeOf(e.parent)?e.frameElement:null}function gn(e){let t=K(e),n=parseFloat(t.width)||0,r=parseFloat(t.height)||0,i=U(e),a=i?e.offsetWidth:n,o=i?e.offsetHeight:r,s=yt(n)!==a||yt(r)!==o;return s&&(n=a,r=o),{width:n,height:r,$:s}}function _n(e){return H(e)?e:e.contextElement}function J(e){let t=_n(e);if(!U(t))return I(1);let n=t.getBoundingClientRect(),{width:r,height:i,$:a}=gn(t),o=(a?yt(n.width):n.width)/r,s=(a?yt(n.height):n.height)/i;return(!o||!Number.isFinite(o))&&(o=1),(!s||!Number.isFinite(s))&&(s=1),{x:o,y:s}}var vn=/* @__PURE__ */ I(0);function yn(e){let t=B(e);return!un()||!t.visualViewport?vn:{x:t.visualViewport.offsetLeft,y:t.visualViewport.offsetTop}}function bn(e,t,n){return t===void 0&&(t=!1),!n||t&&n!==B(e)?!1:t}function Y(e,t,n,r){t===void 0&&(t=!1),n===void 0&&(n=!1);let i=e.getBoundingClientRect(),a=_n(e),o=I(1);t&&(r?H(r)&&(o=J(r)):o=J(e));let s=bn(a,n,r)?yn(a):I(0),c=(i.left+s.x)/o.x,l=(i.top+s.y)/o.y,u=i.width/o.x,d=i.height/o.y;if(a){let e=B(a),t=r&&H(r)?B(r):r,n=e,i=hn(n);for(;i&&r&&t!==n;){let e=J(i),t=i.getBoundingClientRect(),r=K(i),a=t.left+(i.clientLeft+parseFloat(r.paddingLeft))*e.x,o=t.top+(i.clientTop+parseFloat(r.paddingTop))*e.y;c*=e.x,l*=e.y,u*=e.x,d*=e.y,c+=a,l+=o,n=B(i),i=hn(n)}}return Vt({width:u,height:d,x:c,y:l})}function xn(e,t){let n=fn(e).scrollLeft;return t?t.left+n:Y(V(e)).left+n}function Sn(e,t){let n=e.getBoundingClientRect();return{x:n.left+t.scrollLeft-xn(e,n),y:n.top+t.scrollTop}}function Cn(e){let{elements:t,rect:n,offsetParent:r,strategy:i}=e,a=i===`fixed`,o=V(r),s=t?rn(t.floating):!1;if(r===o||s&&a)return n;let c={scrollLeft:0,scrollTop:0},l=I(1),u=I(0),d=U(r);if((d||!d&&!a)&&((z(r)!==`body`||W(o))&&(c=fn(r)),U(r))){let e=Y(r);l=J(r),u.x=e.x+r.clientLeft,u.y=e.y+r.clientTop}let f=o&&!d&&!a?Sn(o,c):I(0);return{width:n.width*l.x,height:n.height*l.y,x:n.x*l.x-c.scrollLeft*l.x+u.x+f.x,y:n.y*l.y-c.scrollTop*l.y+u.y+f.y}}function wn(e){return Array.from(e.getClientRects())}function Tn(e){let t=V(e),n=fn(e),r=e.ownerDocument.body,i=F(t.scrollWidth,t.clientWidth,r.scrollWidth,r.clientWidth),a=F(t.scrollHeight,t.clientHeight,r.scrollHeight,r.clientHeight),o=-n.scrollLeft+xn(e),s=-n.scrollTop;return K(r).direction===`rtl`&&(o+=F(t.clientWidth,r.clientWidth)-i),{width:i,height:a,x:o,y:s}}var En=25;function Dn(e,t){let n=B(e),r=V(e),i=n.visualViewport,a=r.clientWidth,o=r.clientHeight,s=0,c=0;if(i){a=i.width,o=i.height;let e=un();(!e||e&&t===`fixed`)&&(s=i.offsetLeft,c=i.offsetTop)}let l=xn(r);if(l<=0){let e=r.ownerDocument,t=e.body,n=getComputedStyle(t),i=e.compatMode===`CSS1Compat`&&parseFloat(n.marginLeft)+parseFloat(n.marginRight)||0,o=Math.abs(r.clientWidth-t.clientWidth-i);o<=En&&(a-=o)}else l<=En&&(a+=l);return{width:a,height:o,x:s,y:c}}var On=/* @__PURE__ */ new Set([`absolute`,`fixed`]);function kn(e,t){let n=Y(e,!0,t===`fixed`),r=n.top+e.clientTop,i=n.left+e.clientLeft,a=U(e)?J(e):I(1);return{width:e.clientWidth*a.x,height:e.clientHeight*a.y,x:i*a.x,y:r*a.y}}function An(e,t,n){let r;if(t===`viewport`)r=Dn(e,n);else if(t===`document`)r=Tn(V(e));else if(H(t))r=kn(t,n);else{let n=yn(e);r={x:t.x-n.x,y:t.y-n.y,width:t.width,height:t.height}}return Vt(r)}function jn(e,t){let n=q(e);return n===t||!H(n)||G(n)?!1:K(n).position===`fixed`||jn(n,t)}function Mn(e,t){let n=t.get(e);if(n)return n;let r=mn(e,[],!1).filter(e=>H(e)&&z(e)!==`body`),i=null,a=K(e).position===`fixed`,o=a?q(e):e;for(;H(o)&&!G(o);){let t=K(o),n=cn(o);!n&&t.position===`fixed`&&(i=null),(a?!n&&!i:!n&&t.position===`static`&&i&&On.has(i.position)||W(o)&&!n&&jn(e,o))?r=r.filter(e=>e!==o):i=t,o=q(o)}return t.set(e,r),r}function Nn(e){let{element:t,boundary:n,rootBoundary:r,strategy:i}=e,a=[...n===`clippingAncestors`?rn(t)?[]:Mn(t,this._c):[].concat(n),r],o=a[0],s=a.reduce((e,n)=>{let r=An(t,n,i);return e.top=F(r.top,e.top),e.right=vt(r.right,e.right),e.bottom=vt(r.bottom,e.bottom),e.left=F(r.left,e.left),e},An(t,o,i));return{width:s.right-s.left,height:s.bottom-s.top,x:s.left,y:s.top}}function Pn(e){let{width:t,height:n}=gn(e);return{width:t,height:n}}function Fn(e,t,n){let r=U(t),i=V(t),a=n===`fixed`,o=Y(e,!0,a,t),s={scrollLeft:0,scrollTop:0},c=I(0);function l(){c.x=xn(i)}if(r||!r&&!a)if((z(t)!==`body`||W(i))&&(s=fn(t)),r){let e=Y(t,!0,a,t);c.x=e.x+t.clientLeft,c.y=e.y+t.clientTop}else i&&l();a&&!r&&i&&l();let u=i&&!r&&!a?Sn(i,s):I(0);return{x:o.left+s.scrollLeft-c.x-u.x,y:o.top+s.scrollTop-c.y-u.y,width:o.width,height:o.height}}function In(e){return K(e).position===`static`}function Ln(e,t){if(!U(e)||K(e).position===`fixed`)return null;if(t)return t(e);let n=e.offsetParent;return V(e)===n&&(n=n.ownerDocument.body),n}function Rn(e,t){let n=B(e);if(rn(e))return n;if(!U(e)){let t=q(e);for(;t&&!G(t);){if(H(t)&&!In(t))return t;t=q(t)}return n}let r=Ln(e,t);for(;r&&tn(r)&&In(r);)r=Ln(r,t);return r&&G(r)&&In(r)&&!cn(r)?n:r||ln(e)||n}var zn=async function(e){let t=this.getOffsetParent||Rn,n=this.getDimensions,r=await n(e.floating);return{reference:Fn(e.reference,await t(e.floating),e.strategy),floating:{x:0,y:0,width:r.width,height:r.height}}};function Bn(e){return K(e).direction===`rtl`}var Vn={convertOffsetParentRelativeRectToViewportRelativeRect:Cn,getDocumentElement:V,getClippingRect:Nn,getOffsetParent:Rn,getElementRects:zn,getClientRects:wn,getDimensions:Pn,getScale:J,isElement:H,isRTL:Bn},Hn=Jt,Un=Yt,Wn=Gt,Gn=(e,t,n)=>{let r=/* @__PURE__ */ new Map,i={platform:Vn,...n},a={...i.platform,_c:r};return Wt(e,t,{...i,platform:a})},LinkTooltip=class{constructor(e){this.editor=e,this.tooltip=null,this.currentLink=null,this.hideTimeout=null,this.visibilityChangeHandler=null,this.isTooltipHovered=!1,this.linkCacheText=null,this.linkCache=[],this.init()}init(){this.createTooltip(),this.textareaListeners={selectionchange:()=>this.checkCursorPosition(),keyup:e=>{(e.key.includes(`Arrow`)||e.key===`Home`||e.key===`End`)&&this.checkCursorPosition()},input:()=>this.hide(),scroll:()=>{this.currentLink&&this.positionTooltip(this.currentLink)},blur:()=>{this.isTooltipHovered||this.hide()}};for(let[e,t]of Object.entries(this.textareaListeners))this.editor.textarea.addEventListener(e,t);this.visibilityChangeHandler=()=>{document.hidden&&this.hide()},document.addEventListener(`visibilitychange`,this.visibilityChangeHandler),this.tooltip.addEventListener(`mouseenter`,()=>{this.isTooltipHovered=!0,this.cancelHide()}),this.tooltip.addEventListener(`mouseleave`,()=>{this.isTooltipHovered=!1,this.scheduleHide()})}createTooltip(){this.tooltip=document.createElement(`div`),this.tooltip.className=`overtype-link-tooltip`,this.editor._markChrome(this.tooltip),this.tooltip.innerHTML=`
      <span style="display: flex; align-items: center; gap: 6px;">
        <svg width="12" height="12" viewBox="0 0 20 20" fill="currentColor" style="flex-shrink: 0;">
          <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z"></path>
          <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z"></path>
        </svg>
        <span class="overtype-link-tooltip-url"></span>
      </span>
    `,this.tooltip.addEventListener(`click`,e=>{if(e.preventDefault(),e.stopPropagation(),this.currentLink){let e=MarkdownParser.sanitizeUrl(this.currentLink.url);e!==`#`&&window.open(e,`_blank`),this.hide()}}),this.editor.container.appendChild(this.tooltip)}checkCursorPosition(){let e=this.editor.textarea.selectionStart,t=this.editor.textarea.value,n=this.findLinkAtPosition(t,e);n?(!this.currentLink||this.currentLink.url!==n.url||this.currentLink.index!==n.index)&&this.show(n):this.scheduleHide()}findLinkAtPosition(e,t){if(this.editor.options.showActiveLineRaw)return null;let n=!MarkdownParser.resolveDisabled(this.editor.options.disable).has(`code`);(this.linkCacheText!==e||this.linkCacheFences!==n)&&(this.linkCacheText=e,this.linkCacheFences=n,this.linkCache=MarkdownParser.findRenderableLinks(e,{fences:n}));let r=this.linkCache;for(let[e,n]of r.entries()){let r=n.start,i=n.end;if(t>=r&&t<=i)return{text:n.text.raw,url:this.transformUrl(n.destination.value),index:e,start:r,end:i}}return null}transformUrl(e){let t=this.editor.options.transformLinkUrl;if(typeof t!=`function`)return e;try{let n=t(e);return typeof n==`string`?n:e}catch(t){return console.warn(`transformLinkUrl threw:`,t),e}}async show(e){this.currentLink=e,this.cancelHide();let t=this.tooltip.querySelector(`.overtype-link-tooltip-url`);t.textContent=e.url,await this.positionTooltip(e),this.currentLink===e&&this.tooltip.classList.add(`visible`)}async positionTooltip(e){let t=this.findAnchorElement(e.index);if(!t)return;let n=t.getBoundingClientRect();if(!(n.width===0||n.height===0))try{let{x:e,y:n}=await Gn(t,this.tooltip,{strategy:`fixed`,placement:`bottom`,middleware:[Hn(8),Un({padding:8}),Wn()]});Object.assign(this.tooltip.style,{left:`${e}px`,top:`${n}px`,position:`fixed`})}catch(e){console.warn(`Floating UI positioning failed:`,e)}}findAnchorElement(e){return this.editor.preview.querySelector(`a[style*="--link-${e}"]`)}hide(){this.tooltip.classList.remove(`visible`),this.currentLink=null,this.isTooltipHovered=!1}scheduleHide(){this.cancelHide(),this.hideTimeout=setTimeout(()=>this.hide(),300)}cancelHide(){this.hideTimeout&&(clearTimeout(this.hideTimeout),this.hideTimeout=null)}destroy(){if(this.cancelHide(),this.textareaListeners){for(let[e,t]of Object.entries(this.textareaListeners))this.editor.textarea.removeEventListener(e,t);this.textareaListeners=null}this.visibilityChangeHandler&&(document.removeEventListener(`visibilitychange`,this.visibilityChangeHandler),this.visibilityChangeHandler=null),this.tooltip&&this.tooltip.parentNode&&this.tooltip.parentNode.removeChild(this.tooltip),this.tooltip=null,this.currentLink=null,this.isTooltipHovered=!1}},X={bold:{name:`bold`,actionId:`toggleBold`,icon:`<svg viewBox="0 0 18 18">
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5,4H9.5A2.5,2.5,0,0,1,12,6.5v0A2.5,2.5,0,0,1,9.5,9H5A0,0,0,0,1,5,9V4A0,0,0,0,1,5,4Z"></path>
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5,9h5.5A2.5,2.5,0,0,1,13,11.5v0A2.5,2.5,0,0,1,10.5,14H5a0,0,0,0,1,0,0V9A0,0,0,0,1,5,9Z"></path>
</svg>`,title:`Bold (Ctrl+B)`,isActive:({activeFormats:e})=>e.includes(`bold`),action:({editor:e})=>{nt(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},italic:{name:`italic`,actionId:`toggleItalic`,icon:`<svg viewBox="0 0 18 18">
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="7" x2="13" y1="4" y2="4"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="5" x2="11" y1="14" y2="14"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="8" x2="10" y1="14" y2="4"></line>
</svg>`,title:`Italic (Ctrl+I)`,isActive:({activeFormats:e})=>e.includes(`italic`),action:({editor:e})=>{rt(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},code:{name:`code`,actionId:`toggleCode`,icon:`<svg viewBox="0 0 18 18">
  <polyline stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" points="5 7 3 9 5 11"></polyline>
  <polyline stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" points="13 7 15 9 13 11"></polyline>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="10" x2="8" y1="5" y2="13"></line>
</svg>`,title:`Inline Code`,isActive:()=>!1,action:({editor:e})=>{it(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},separator:{name:`separator`},link:{name:`link`,actionId:`insertLink`,icon:`<svg viewBox="0 0 18 18">
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="7" x2="11" y1="7" y2="11"></line>
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.9,4.577a3.476,3.476,0,0,1,.36,4.679A3.476,3.476,0,0,1,4.577,8.9C3.185,7.5,2.035,6.4,4.217,4.217S7.5,3.185,8.9,4.577Z"></path>
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.423,9.1a3.476,3.476,0,0,0-4.679-.36,3.476,3.476,0,0,0,.36,4.679c1.392,1.392,2.5,2.542,4.679.36S14.815,10.5,13.423,9.1Z"></path>
</svg>`,title:`Insert Link`,action:({editor:e})=>{at(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},h1:{name:`h1`,actionId:`toggleH1`,icon:`<svg viewBox="0 0 18 18">
  <path fill="currentColor" d="M10,4V14a1,1,0,0,1-2,0V10H3v4a1,1,0,0,1-2,0V4A1,1,0,0,1,3,4V8H8V4a1,1,0,0,1,2,0Zm6.06787,9.209H14.98975V7.59863a.54085.54085,0,0,0-.605-.60547h-.62744a1.01119,1.01119,0,0,0-.748.29688L11.645,8.56641a.5435.5435,0,0,0-.022.8584l.28613.30762a.53861.53861,0,0,0,.84717.0332l.09912-.08789a1.2137,1.2137,0,0,0,.2417-.35254h.02246s-.01123.30859-.01123.60547V13.209H12.041a.54085.54085,0,0,0-.605.60547v.43945a.54085.54085,0,0,0,.605.60547h4.02686a.54085.54085,0,0,0,.605-.60547v-.43945A.54085.54085,0,0,0,16.06787,13.209Z"></path>
</svg>`,title:`Heading 1`,isActive:({activeFormats:e})=>e.includes(`header`),action:({editor:e})=>{ut(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},h2:{name:`h2`,actionId:`toggleH2`,icon:`<svg viewBox="0 0 18 18">
  <path fill="currentColor" d="M16.73975,13.81445v.43945a.54085.54085,0,0,1-.605.60547H11.855a.58392.58392,0,0,1-.64893-.60547V14.0127c0-2.90527,3.39941-3.42187,3.39941-4.55469a.77675.77675,0,0,0-.84717-.78125,1.17684,1.17684,0,0,0-.83594.38477c-.2749.26367-.561.374-.85791.13184l-.4292-.34082c-.30811-.24219-.38525-.51758-.1543-.81445a2.97155,2.97155,0,0,1,2.45361-1.17676,2.45393,2.45393,0,0,1,2.68408,2.40918c0,2.45312-3.1792,2.92676-3.27832,3.93848h2.79443A.54085.54085,0,0,1,16.73975,13.81445ZM9,3A.99974.99974,0,0,0,8,4V8H3V4A1,1,0,0,0,1,4V14a1,1,0,0,0,2,0V10H8v4a1,1,0,0,0,2,0V4A.99974.99974,0,0,0,9,3Z"></path>
</svg>`,title:`Heading 2`,isActive:({activeFormats:e})=>e.includes(`header-2`),action:({editor:e})=>{dt(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},h3:{name:`h3`,actionId:`toggleH3`,icon:`<svg viewBox="0 0 18 18">
  <path fill="currentColor" d="M16.65186,12.30664a2.6742,2.6742,0,0,1-2.915,2.68457,3.96592,3.96592,0,0,1-2.25537-.6709.56007.56007,0,0,1-.13232-.83594L11.64648,13c.209-.34082.48389-.36328.82471-.1543a2.32654,2.32654,0,0,0,1.12256.33008c.71484,0,1.12207-.35156,1.12207-.78125,0-.61523-.61621-.86816-1.46338-.86816H13.2085a.65159.65159,0,0,1-.68213-.41895l-.05518-.10937a.67114.67114,0,0,1,.14307-.78125l.71533-.86914a8.55289,8.55289,0,0,1,.68213-.7373V8.58887a3.93913,3.93913,0,0,1-.748.05469H11.9873a.54085.54085,0,0,1-.605-.60547V7.59863a.54085.54085,0,0,1,.605-.60547h3.75146a.53773.53773,0,0,1,.60547.59375v.17676a1.03723,1.03723,0,0,1-.27539.748L14.74854,10.0293A2.31132,2.31132,0,0,1,16.65186,12.30664ZM9,3A.99974.99974,0,0,0,8,4V8H3V4A1,1,0,0,0,1,4V14a1,1,0,0,0,2,0V10H8v4a1,1,0,0,0,2,0V4A.99974.99974,0,0,0,9,3Z"></path>
</svg>`,title:`Heading 3`,isActive:({activeFormats:e})=>e.includes(`header-3`),action:({editor:e})=>{ft(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},bulletList:{name:`bulletList`,actionId:`toggleBulletList`,icon:`<svg viewBox="0 0 18 18">
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="6" x2="15" y1="4" y2="4"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="6" x2="15" y1="9" y2="9"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="6" x2="15" y1="14" y2="14"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="3" x2="3" y1="4" y2="4"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="3" x2="3" y1="9" y2="9"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="3" x2="3" y1="14" y2="14"></line>
</svg>`,title:`Bullet List`,isActive:({activeFormats:e})=>e.includes(`bullet-list`),action:({editor:e})=>{ot(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},orderedList:{name:`orderedList`,actionId:`toggleNumberedList`,icon:`<svg viewBox="0 0 18 18">
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="7" x2="15" y1="4" y2="4"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="7" x2="15" y1="9" y2="9"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="7" x2="15" y1="14" y2="14"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="1" x1="2.5" x2="4.5" y1="5.5" y2="5.5"></line>
  <path fill="currentColor" d="M3.5,6A0.5,0.5,0,0,1,3,5.5V3.085l-0.276.138A0.5,0.5,0,0,1,2.053,3c-0.124-.247-0.023-0.324.224-0.447l1-.5A0.5,0.5,0,0,1,4,2.5v3A0.5,0.5,0,0,1,3.5,6Z"></path>
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M4.5,10.5h-2c0-.234,1.85-1.076,1.85-2.234A0.959,0.959,0,0,0,2.5,8.156"></path>
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M2.5,14.846a0.959,0.959,0,0,0,1.85-.109A0.7,0.7,0,0,0,3.75,14a0.688,0.688,0,0,0,.6-0.736,0.959,0.959,0,0,0-1.85-.109"></path>
</svg>`,title:`Numbered List`,isActive:({activeFormats:e})=>e.includes(`numbered-list`),action:({editor:e})=>{st(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},taskList:{name:`taskList`,actionId:`toggleTaskList`,icon:`<svg viewBox="0 0 18 18">
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="8" x2="16" y1="4" y2="4"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="8" x2="16" y1="9" y2="9"></line>
  <line stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" x1="8" x2="16" y1="14" y2="14"></line>
  <rect stroke="currentColor" fill="none" stroke-width="1.5" x="2" y="3" width="3" height="3" rx="0.5"></rect>
  <rect stroke="currentColor" fill="none" stroke-width="1.5" x="2" y="13" width="3" height="3" rx="0.5"></rect>
  <polyline stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" points="2.65 9.5 3.5 10.5 5 8.5"></polyline>
</svg>`,title:`Task List`,isActive:({activeFormats:e})=>e.includes(`task-list`),action:({editor:e})=>{lt&&(lt(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0})))}},quote:{name:`quote`,actionId:`toggleQuote`,icon:`<svg viewBox="2 2 20 20">
  <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 10.8182L9 10.8182C8.80222 10.8182 8.60888 10.7649 8.44443 10.665C8.27998 10.5651 8.15181 10.4231 8.07612 10.257C8.00043 10.0909 7.98063 9.90808 8.01922 9.73174C8.0578 9.55539 8.15304 9.39341 8.29289 9.26627C8.43275 9.13913 8.61093 9.05255 8.80491 9.01747C8.99889 8.98239 9.19996 9.00039 9.38268 9.0692C9.56541 9.13801 9.72159 9.25453 9.83147 9.40403C9.94135 9.55353 10 9.72929 10 9.90909L10 12.1818C10 12.664 9.78929 13.1265 9.41421 13.4675C9.03914 13.8084 8.53043 14 8 14"></path>
  <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 10.8182L15 10.8182C14.8022 10.8182 14.6089 10.7649 14.4444 10.665C14.28 10.5651 14.1518 10.4231 14.0761 10.257C14.0004 10.0909 13.9806 9.90808 14.0192 9.73174C14.0578 9.55539 14.153 9.39341 14.2929 9.26627C14.4327 9.13913 14.6109 9.05255 14.8049 9.01747C14.9989 8.98239 15.2 9.00039 15.3827 9.0692C15.5654 9.13801 15.7216 9.25453 15.8315 9.40403C15.9414 9.55353 16 9.72929 16 9.90909L16 12.1818C16 12.664 15.7893 13.1265 15.4142 13.4675C15.0391 13.8084 14.5304 14 14 14"></path>
</svg>`,title:`Quote`,isActive:({activeFormats:e})=>e.includes(`quote`),action:({editor:e})=>{ct(e.textarea),e.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}},upload:{name:`upload`,actionId:`uploadFile`,icon:`<svg viewBox="0 0 18 18">
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.25 12.375v1.688A1.688 1.688 0 0 0 3.938 15.75h10.124a1.688 1.688 0 0 0 1.688-1.688V12.375"></path>
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.063 6.188L9 2.25l3.938 3.938"></path>
  <path stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 2.25v10.125"></path>
</svg>`,title:`Upload File`,action:({editor:e})=>{var t,n;if(!((t=e.options.fileUpload)!=null&&t.enabled))return;let r=document.createElement(`input`);r.type=`file`,r.multiple=!0,((n=e.options.fileUpload.mimeTypes)==null?void 0:n.length)>0&&(r.accept=e.options.fileUpload.mimeTypes.join(`,`)),r.onchange=()=>{var t;if(!((t=r.files)!=null&&t.length))return;let n=new DataTransfer;for(let e of r.files)n.items.add(e);e._handleDataTransfer(n)},r.click()}},viewMode:{name:`viewMode`,icon:`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" fill="none"></path>
  <circle cx="12" cy="12" r="3" fill="none"></circle>
</svg>`,title:`View mode`}},Kn=[X.bold,X.italic,X.code,X.separator,X.link,X.separator,X.h1,X.h2,X.h3,X.separator,X.bulletList,X.orderedList,X.taskList,X.separator,X.quote,X.separator,X.viewMode],Z;function qn(){if(Z!==void 0)return Z;if(Z=!1,typeof navigator<`u`){let e=navigator.userAgent||``;Z=/^((?!chrome|android|crios|fxios|edg|opr).)*safari/i.test(e)||/iPad|iPhone|iPod/.test(e)||navigator.platform===`MacIntel`&&navigator.maxTouchPoints>1&&/Safari/.test(e)}return Z}function Jn(e){let t={};return(e||[]).forEach(e=>{if(!e||e.name===`separator`)return;let n=e.actionId||e.name;e.action&&(t[n]=e.action)}),t}function Yn(e){let t=e||Kn;return Array.isArray(t)?t.map(e=>({name:(e==null?void 0:e.name)||null,actionId:(e==null?void 0:e.actionId)||(e==null?void 0:e.name)||null,icon:(e==null?void 0:e.icon)||null,title:(e==null?void 0:e.title)||null})):null}var Xn={toggleH1:`h1`,toggleH2:`h2`,toggleH3:`h3`,toggleBulletList:`lists`,toggleNumberedList:`lists`,toggleTaskList:`tasks`,toggleQuote:`blockquote`};function Zn(e,t){let n=Yn(e),r=Yn(t);if(n===null||r===null)return n!==r;if(n.length!==r.length)return!0;for(let e=0;e<n.length;e++){let t=n[e],i=r[e];if(t.name!==i.name||t.actionId!==i.actionId||t.icon!==i.icon||t.title!==i.title)return!0}return!1}var Q=class _OverType{constructor(e,t={}){let n=_OverType._resolveTargets(e);if(typeof e==`string`&&n.length===0)throw Error(`No elements found for selector: ${e}`);return n.map(e=>{if(e.overTypeInstance)return e.overTypeInstance.reinit(t),e.overTypeInstance;let n=Object.create(_OverType.prototype);return n._init(e,t),e.overTypeInstance=n,_OverType.instances.set(e,n),n})}_init(e,t={}){var n;this.element=e,this.instanceTheme=t.theme||null,this.options=this._mergeOptions(t),this.instanceId=++_OverType.instanceCount,this.initialized=!1,this._isSafari=qn(),this._safariReflowRaf=null,this.options.persist&&!_OverType.stylesChrome&&(_OverType.stylesChrome=!0,(n=document.querySelector(`style.overtype-styles`))==null||n.setAttribute(`clay`,`editor-ui`)),this.options.persist&&_OverType._registerClaySnapshotHook(),_OverType.injectStyles(),_OverType.initGlobalListeners();let r=e.querySelector(`.overtype-container`),i=e.querySelector(`.overtype-wrapper`);r||i?this._recoverFromDOM(r,i):this._buildFromScratch(),this.instanceTheme===`auto`&&this.setTheme(`auto`),this.shortcuts=new ShortcutsManager(this),this._rebuildActionsMap(),this.linkTooltip=new LinkTooltip(this),requestAnimationFrame(()=>{requestAnimationFrame(()=>{this.textarea.scrollTop=this.preview.scrollTop,this.textarea.scrollLeft=this.preview.scrollLeft})}),this.initialized=!0,this.options.onChange&&this._notifyChange()}_mergeOptions(e){let t={fontSize:`14px`,lineHeight:1.6,fontFamily:`"SF Mono", SFMono-Regular, Menlo, Monaco, "Cascadia Code", Consolas, "Roboto Mono", "Noto Sans Mono", "Droid Sans Mono", "Ubuntu Mono", "DejaVu Sans Mono", "Liberation Mono", "Courier New", Courier, monospace`,padding:`16px`,mobile:{fontSize:`16px`,padding:`12px`,lineHeight:1.5},textareaProps:{},autofocus:!1,autoResize:!1,minHeight:`100px`,maxHeight:null,placeholder:`Start typing...`,value:``,onChange:null,onKeydown:null,onRender:null,onFocus:null,onBlur:null,showActiveLineRaw:!1,showStats:!1,toolbar:!1,toolbarButtons:null,statsFormatter:null,smartLists:!0,clickToToggleTasks:!1,codeHighlighter:null,customSyntax:null,disable:[],spellcheck:!1,persist:!1,transformLinkUrl:null},{theme:n,colors:r,...i}=e;return{...t,...i}}_recoverFromDOM(e,t){let n=this._extractContent();if(e&&e.classList.contains(`overtype-container`)?(this.container=e,this.wrapper=e.querySelector(`.overtype-wrapper`)):t&&(this.wrapper=t,this.container=document.createElement(`div`),this.container.className=`overtype-container`,t.parentNode.insertBefore(this.container,t),this.container.appendChild(t)),this.textarea=this.wrapper?this.wrapper.querySelector(`.overtype-input`):null,!this.textarea){e&&e.remove(),t&&t.remove(),this._buildFromScratch(n);return}let r=this.instanceTheme||_OverType.currentTheme||C,i=typeof r==`string`?r:r.name;i&&this.container.setAttribute(`data-theme`,i),this.instanceTheme&&this._applyThemeVars(typeof this.instanceTheme==`string`?w(this.instanceTheme):this.instanceTheme),this.container.querySelectorAll(`.overtype-toolbar, .overtype-link-tooltip, .overtype-stats, .overtype-placeholder, .overtype-preview`).forEach(e=>e.remove()),this.container.classList.remove(`overtype-auto-resize`),[this.wrapper,this.textarea].forEach(e=>{e.style.removeProperty(`height`),e.style.removeProperty(`overflow-y`)}),this._createOverlay(),this.options.showStats&&this._createStatsBar(),this.wrapper._instance=this,this._applyInstanceCSSVars(),this._configureTextarea(),this._ensureTextareaId(),this._syncPreviewInteractivity(),this._applyOptions()}_buildFromScratch(e=this._extractContent()){this.element.innerHTML=``,this._createDOM(),(e||this.options.value)&&this.setValue(e||this.options.value),this._applyOptions()}_extractContent(){let e=this.element.querySelector(`.overtype-input`);return e?e.value:this.element.textContent||``}_createDOM(){this.container=document.createElement(`div`),this.container.className=`overtype-container`;let e=this.instanceTheme||_OverType.currentTheme||C,t=typeof e==`string`?e:e.name;t&&this.container.setAttribute(`data-theme`,t),this.instanceTheme&&this._applyThemeVars(typeof this.instanceTheme==`string`?w(this.instanceTheme):this.instanceTheme),this.wrapper=document.createElement(`div`),this.wrapper.className=`overtype-wrapper`,this._applyInstanceCSSVars(),this.wrapper._instance=this,this.textarea=document.createElement(`textarea`),this.textarea.className=`overtype-input`,this.textarea.placeholder=this.options.placeholder,this._configureTextarea(),this.options.textareaProps&&Object.entries(this.options.textareaProps).forEach(([e,t])=>{e===`className`||e===`class`?this.textarea.className+=` `+t:e===`style`&&typeof t==`object`?Object.assign(this.textarea.style,t):this.textarea.setAttribute(e,t)}),this._ensureTextareaId(),this.wrapper.appendChild(this.textarea),this._createOverlay(),this.container.appendChild(this.wrapper),this.options.showStats&&this._createStatsBar(),this.element.appendChild(this.container),this.options.autoResize?this._setupAutoResize():this.container.classList.remove(`overtype-auto-resize`),this._syncPreviewInteractivity()}_createOverlay(){this.preview=document.createElement(`div`),this.preview.className=`overtype-preview`,this.preview.setAttribute(`aria-hidden`,`true`),this.placeholderEl=document.createElement(`div`),this.placeholderEl.className=`overtype-placeholder`,this.placeholderEl.setAttribute(`aria-hidden`,`true`),this.placeholderEl.textContent=this.options.placeholder,this.wrapper.appendChild(this.preview),this.wrapper.appendChild(this.placeholderEl),this._markChrome(this.preview),this._markChrome(this.placeholderEl)}_createStatsBar(){this.statsBar=document.createElement(`div`),this.statsBar.className=`overtype-stats`,this._markChrome(this.statsBar),this.container.appendChild(this.statsBar),this._updateStats()}_markChrome(e){this.options.persist&&e&&e.setAttribute(`clay`,`editor-ui`)}_configureTextarea(){this.textarea.setAttribute(`autocomplete`,`off`),this.textarea.setAttribute(`autocorrect`,`off`),this.textarea.setAttribute(`autocapitalize`,`off`),this.textarea.setAttribute(`spellcheck`,String(this.options.spellcheck)),this.textarea.setAttribute(`data-gramm`,`false`),this.textarea.setAttribute(`data-gramm_editor`,`false`),this.textarea.setAttribute(`data-enable-grammarly`,`false`),this.options.persist&&this.textarea.setAttribute(`persist`,``)}_ensureTextareaId(){let e=this.textarea.id,t=/^overtype-\d+-input$/.test(e);if(e&&!(t&&document.querySelectorAll(`[id="${e}"]`).length>1))return;let n=this.instanceId;for(;document.getElementById(`overtype-${n}-input`);)n++;this.textarea.id=`overtype-${n}-input`}_syncPreviewInteractivity(){if(!this.preview||!this.container)return;let e=this.container.dataset.mode===`preview`;if(this.preview.inert=!e,this.preview.toggleAttribute(`inert`,!e),e){this.preview.removeAttribute(`aria-hidden`);return}this.preview.setAttribute(`aria-hidden`,`true`)}_createToolbar(){var e;let t=this.options.toolbarButtons||Kn;if((e=this.options.fileUpload)!=null&&e.enabled&&!t.some(e=>(e==null?void 0:e.name)===`upload`)){let e=t.findIndex(e=>(e==null?void 0:e.name)===`viewMode`);e===-1?t=[...t,X.separator,X.upload]:(t=[...t],t.splice(e,0,X.separator,X.upload))}t=this._withoutDisabledButtons(t),this.toolbar=new Toolbar(this,{toolbarButtons:t}),this.toolbar.create(),this._toolbarSelectionListener=()=>{this.toolbar&&this.toolbar.updateButtonStates()},this._toolbarInputListener=()=>{this.toolbar&&this.toolbar.updateButtonStates()},this.textarea.addEventListener(`selectionchange`,this._toolbarSelectionListener),this.textarea.addEventListener(`input`,this._toolbarInputListener)}_cleanupToolbarListeners(){this._toolbarSelectionListener&&(this.textarea.removeEventListener(`selectionchange`,this._toolbarSelectionListener),this._toolbarSelectionListener=null),this._toolbarInputListener&&(this.textarea.removeEventListener(`input`,this._toolbarInputListener),this._toolbarInputListener=null)}_rebuildActionsMap(){var e;this.actionsById=Jn(Kn),this.options.toolbarButtons&&Object.assign(this.actionsById,Jn(this.options.toolbarButtons)),(e=this.options.fileUpload)!=null&&e.enabled&&Object.assign(this.actionsById,Jn([X.upload]))}_applyInstanceCSSVars(){if(!this.wrapper)return;let e=[[`--instance-font-size`,this.options.fontSize,T.fontSize],[`--instance-line-height`,this.options.lineHeight,T.lineHeight],[`--instance-padding`,this.options.padding,T.padding],[`--instance-font-family`,this.options.fontFamily,T.fontFamily]];for(let[t,n,r]of e)n&&String(n)!==String(r)?this.wrapper.style.setProperty(t,String(n)):this.wrapper.style.removeProperty(t)}_applyOptions(){this._applyInstanceCSSVars(),this.options.autofocus&&this.textarea.focus(),this.options.autoResize?this.container.classList.contains(`overtype-auto-resize`)?this._updateAutoHeight():this._setupAutoResize():this.container.classList.remove(`overtype-auto-resize`),this.options.toolbar&&!this.toolbar?this._createToolbar():!this.options.toolbar&&this.toolbar&&(this._cleanupToolbarListeners(),this.toolbar.destroy(),this.toolbar=null),this.placeholderEl&&(this.placeholderEl.textContent=this.options.placeholder),this.options.fileUpload&&!this.fileUploadInitialized?this._initFileUpload():!this.options.fileUpload&&this.fileUploadInitialized&&this._destroyFileUpload(),this.updatePreview()}_initFileUpload(){let e=this.options.fileUpload;if(!(!e||!e.enabled)){if(e.maxSize=e.maxSize||10*1024*1024,e.mimeTypes=e.mimeTypes||[],e.batch=e.batch||!1,!e.onInsertFile||typeof e.onInsertFile!=`function`){console.warn(`OverType: fileUpload.onInsertFile callback is required for file uploads.`);return}this._fileUploadCounter=0,this._uploadedFiles=/* @__PURE__ */ new Map,this._boundHandleFilePaste=this._handleFilePaste.bind(this),this._boundHandleFileDrop=this._handleFileDrop.bind(this),this._boundHandleDragOver=this._handleDragOver.bind(this),this.textarea.addEventListener(`paste`,this._boundHandleFilePaste),this.textarea.addEventListener(`drop`,this._boundHandleFileDrop),this.textarea.addEventListener(`dragover`,this._boundHandleDragOver),this.fileUploadInitialized=!0}}_extractMarkdownUrls(e){return MarkdownParser.findLinks(e,{allowEmptyText:!0}).map(e=>e.destination.value)}_trackInsertedUrls(e,t){if(!this._uploadedFiles||!t||!e)return;let n=MarkdownParser.findLinks(e,{allowEmptyText:!0});for(let e of n)this._uploadedFiles.set(e.destination.value,{filename:t.name,file:t,markdownDestination:e.destination.raw})}_checkForRemovedUploads(){var e;if(!this._uploadedFiles||this._uploadedFiles.size===0)return;let t=(e=this.options.fileUpload)==null?void 0:e.onRemoveFile,n=this.textarea.value,r=new Set(this._extractMarkdownUrls(this.textarea.value)),i=[];for(let[e,t]of this._uploadedFiles){let a=t.markdownDestination||e;!r.has(e)&&!n.includes(a)&&i.push({url:e,info:t})}for(let{url:e,info:n}of i)this._uploadedFiles.delete(e),t&&t({url:e,filename:n.filename,file:n.file})}_handleFilePaste(e){var t,n;(n=(t=e==null?void 0:e.clipboardData)==null?void 0:t.files)!=null&&n.length&&(e.preventDefault(),this._handleDataTransfer(e.clipboardData))}_handleFileDrop(e){var t,n;(n=(t=e==null?void 0:e.dataTransfer)==null?void 0:t.files)!=null&&n.length&&(e.preventDefault(),this._handleDataTransfer(e.dataTransfer))}_handleDataTransfer(e){let t=[];for(let n of e.files){if(n.size>this.options.fileUpload.maxSize||this.options.fileUpload.mimeTypes.length>0&&!this.options.fileUpload.mimeTypes.includes(n.type))continue;let e=++this._fileUploadCounter,r=`${n.type.startsWith(`image/`)?`!`:``}[Uploading ${n.name} (#${e})...]()`;if(this.insertAtCursor(`${r}
`),this.options.fileUpload.batch){t.push({file:n,placeholder:r});continue}this.options.fileUpload.onInsertFile(n).then(e=>{this.textarea.value=this.textarea.value.replace(r,e),this._trackInsertedUrls(e,n),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))},e=>{console.error(`OverType: File upload failed`,e),this.textarea.value=this.textarea.value.replace(r,`[Upload failed]()`),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))})}this.options.fileUpload.batch&&t.length>0&&this.options.fileUpload.onInsertFile(t.map(e=>e.file)).then(e=>{(Array.isArray(e)?e:[e]).forEach((e,n)=>{this.textarea.value=this.textarea.value.replace(t[n].placeholder,e),this._trackInsertedUrls(e,t[n].file)}),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))},e=>{console.error(`OverType: File upload failed`,e),t.forEach(({placeholder:e})=>{this.textarea.value=this.textarea.value.replace(e,`[Upload failed]()`)}),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))})}_handleDragOver(e){e.preventDefault()}_destroyFileUpload(){this.textarea.removeEventListener(`paste`,this._boundHandleFilePaste),this.textarea.removeEventListener(`drop`,this._boundHandleFileDrop),this.textarea.removeEventListener(`dragover`,this._boundHandleDragOver),this._boundHandleFilePaste=null,this._boundHandleFileDrop=null,this._boundHandleDragOver=null,this._uploadedFiles=null,this.fileUploadInitialized=!1}_handleTaskClick(e){if(!this.options.clickToToggleTasks||e.button!==0||!this._canEditTextarea()||this.container.dataset.mode===`preview`)return;let t=this._disabledFeatures();if(t.has(`tasks`))return;let n=[...this.preview.querySelectorAll(`li.task-list, div.raw-line`)].filter(e=>e.matches(`li.task-list`)||/^ *-\s+\[[ xX]\](?:\s|$)/.test(e.textContent)),r=0,i=0,a=null;for(let o of this.textarea.value.split(`
`)){if(a){l(o,a)&&(a=null),i+=o.length+1;continue}if(a=t.has(`code`)?null:c(o),a){i+=o.length+1;continue}let s=/^( *-\s+\[)([ xX])\](?:\s|$)/.exec(o);if(!s||!MarkdownParser.parseLine(o,!1,t).includes(`<li class="task-list">`)){i+=o.length+1;continue}let u=n[r++],d=u!=null&&u.matches(`li.task-list`)?u.querySelector(`:scope > .syntax-marker`):u,f=d==null?void 0:d.firstChild;if((f==null?void 0:f.nodeType)===3){let t=f.textContent.indexOf(`[`)+1;if(!/^\[[ xX]\]$/.test(f.textContent.slice(t-1,t+2))){i+=o.length+1;continue}let n=document.createRange();if(n.setStart(f,t-1),n.setEnd(f,t+2),[...n.getClientRects()].some(t=>e.clientX>=t.left&&e.clientX<t.right&&e.clientY>=t.top&&e.clientY<t.bottom)){let e=this.textarea,t=e.selectionStart,n=e.selectionEnd,r=e.selectionDirection,a=i+s[1].length;e.focus(),e.setSelectionRange(a,a+1);let o=s[2]===` `?`x`:` `,c=!1,l=()=>{c=!0};e.addEventListener(`input`,l);let u=!1;try{u=document.execCommand(`insertText`,!1,o)}catch(e){}finally{e.removeEventListener(`input`,l)}u||e.setRangeText(o,a,a+1,`preserve`),c||e.dispatchEvent(new Event(`input`,{bubbles:!0})),e.setSelectionRange(t,n,r);return}}i+=o.length+1}}insertAtCursor(e){let t=this.textarea.selectionStart,n=this.textarea.selectionEnd,r=!1;try{r=document.execCommand(`insertText`,!1,e)}catch(e){}if(!r){let r=this.textarea.value.slice(0,t),i=this.textarea.value.slice(n);this.textarea.value=r+e+i,this.textarea.setSelectionRange(t+e.length,t+e.length)}this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}updatePreview(){let e=this.textarea.value,t=this.textarea.selectionStart,n=this._getCurrentLine(e,t),r=this.container.dataset.mode===`preview`,i=MarkdownParser.parse(e,n,this.options.showActiveLineRaw,this.options.codeHighlighter,r,this._parserOptions());this.preview.innerHTML=i,this.placeholderEl&&(this.placeholderEl.style.display=e?`none`:``),this._applyCodeBlockBackgrounds(),this.options.showStats&&this.statsBar&&this._updateStats(),this.options.onRender&&this.options.onRender(this.preview,r?`preview`:`normal`,this)}_notifyChange(){this.initialized&&(this._checkForRemovedUploads(),this.options.onChange&&this.options.onChange(this.textarea.value,this))}_applyCodeBlockBackgrounds(){let e=this.preview.querySelectorAll(`.code-fence`);for(let t=0;t<e.length-1;t+=2){let n=e[t],r=e[t+1],i=n.parentElement,a=r.parentElement;!i||!a||(n.style.display=`block`,r.style.display=`block`,i.classList.add(`code-block-line`),a.classList.add(`code-block-line`))}}_getCurrentLine(e,t){return e.substring(0,t).split(`
`).length-1}handleInput(e){this.updatePreview(),this._notifyChange(),this._scheduleSafariReflow()}_scheduleSafariReflow(){!this._isSafari||this._safariReflowRaf||(this._safariReflowRaf=requestAnimationFrame(()=>{this._safariReflowRaf=null;let e=this.textarea;e&&(e.style.setProperty(`letter-spacing`,`-0.001px`,`important`),e.offsetHeight,e.style.removeProperty(`letter-spacing`))}))}handleFocus(e){this.options.onFocus&&this.options.onFocus(e,this)}handleBlur(e){this.options.onBlur&&this.options.onBlur(e,this)}handleKeydown(e){if(e.key===`Tab`&&this.textarea.selectionStart!==this.textarea.selectionEnd&&this._canEditTextarea()){e.preventDefault(),e.shiftKey?this.outdentSelection():this.indentSelection();return}if(e.key===`Enter`&&!e.shiftKey&&!e.metaKey&&!e.ctrlKey&&this.options.smartLists&&this.handleSmartListContinuation()){e.preventDefault();return}!this.shortcuts.handleKeydown(e)&&this.options.onKeydown&&this.options.onKeydown(e,this)}handleSmartListContinuation(){let e=this._disabledFeatures();if(e.has(`lists`))return!1;let t=this.textarea,n=t.selectionStart,r=MarkdownParser.getListContext(t.value,n,e);return!r||!r.inList?!1:r.content.trim()===``&&n>=r.markerEndPos?(this.deleteListMarker(r),!0):(n>r.markerEndPos&&n<r.lineEnd?this.splitListItem(r,n):this.insertNewListItem(r),r.listType===`numbered`&&this.scheduleNumberedListUpdate(),!0)}deleteListMarker(e){this.textarea.setSelectionRange(e.lineStart,e.markerEndPos),document.execCommand(`delete`),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}insertNewListItem(e){let t=MarkdownParser.createNewListItem(e);document.execCommand(`insertText`,!1,`
`+t),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}splitListItem(e,t){let n=e.content.substring(t-e.markerEndPos);this.textarea.setSelectionRange(t,e.lineEnd),document.execCommand(`delete`);let r=MarkdownParser.createNewListItem(e);document.execCommand(`insertText`,!1,`
`+r+n);let i=this.textarea.selectionStart-n.length;this.textarea.setSelectionRange(i,i),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}scheduleNumberedListUpdate(){this.numberUpdateTimeout&&clearTimeout(this.numberUpdateTimeout),this.numberUpdateTimeout=setTimeout(()=>{this.updateNumberedLists()},10)}updateNumberedLists(){let e=this.textarea.value,t=this.textarea.selectionStart,n=MarkdownParser.renumberLists(e);if(n!==e){let r=0,i=e.split(`
`),a=n.split(`
`),o=0;for(let e=0;e<i.length&&o<t;e++){if(i[e]!==a[e]){let n=a[e].length-i[e].length;o+i[e].length<t&&(r+=n)}o+=i[e].length+1}this.textarea.value=n;let s=t+r;this.textarea.setSelectionRange(s,s),this.textarea.dispatchEvent(new Event(`input`,{bubbles:!0}))}}handleScroll(e){this.preview.scrollTop=this.textarea.scrollTop,this.preview.scrollLeft=this.textarea.scrollLeft}getValue(){return this.textarea.value}setValue(e){let t=this.textarea.value!==e;this.textarea.value=e,this.updatePreview(),this.options.autoResize&&this._updateAutoHeight(),t&&(this._notifyChange(),this._scheduleSafariReflow())}_refreshFromTextarea(){this._syncPreviewInteractivity(),this.updatePreview(),this.options.autoResize&&this._updateAutoHeight(),this._scheduleSafariReflow()}async performAction(e,t=null){var n;let r=this.textarea;if(!r)return!1;let i=(n=this.actionsById)==null?void 0:n[e];if(!i)return console.warn(`OverType: Unknown action "${e}"`),!1;if(this._disabledFeatures().has(Xn[e]))return!1;r.focus();try{return await i({editor:this,getValue:()=>this.getValue(),setValue:e=>this.setValue(e),event:t}),!0}catch(t){return console.error(`OverType: Action "${e}" error:`,t),this.wrapper.dispatchEvent(new CustomEvent(`button-error`,{detail:{actionId:e,error:t}})),!1}}getRenderedHTML(e={}){let t=this.getValue(),n=MarkdownParser.parse(t,-1,!1,this.options.codeHighlighter,!1,this._parserOptions());return e.cleanHTML&&(n=n.replace(/<span class="syntax-marker[^"]*">.*?<\/span>/g,``),n=n.replace(/\sclass="(bullet-list|ordered-list|code-fence|hr-marker|blockquote|url-part)"/g,``),n=n.replace(/\sclass=""/g,``)),n}getPreviewHTML(){return this.preview.innerHTML}indentSelection(){this._replaceSelectedLines(e=>`  ${e}`)}outdentSelection(){this._replaceSelectedLines(e=>e.replace(/^( {1,2}|\t)/,``))}_replaceSelectedLines(e){if(!this._canEditTextarea())return!1;let t=this.textarea,{selectionStart:n,selectionEnd:r,value:i}=t,a=i.lastIndexOf(`
`,n-1)+1,o=this._effectiveSelectionEnd(i,n,r),s=i.indexOf(`
`,o),c=s===-1?i.length:s,l=i.slice(a,c),u=l.split(`
`).map(e).join(`
`);if(u===l)return!1;t.setSelectionRange(a,c);let d=!1;try{d=document.execCommand(`insertText`,!1,u)}catch(e){}return d||t.setRangeText(u,a,c,`preserve`),t.setSelectionRange(a,a+u.length),t.dispatchEvent(new Event(`input`,{bubbles:!0})),!0}_effectiveSelectionEnd(e,t,n){return n>t&&e[n-1]===`
`?n-1:n}_canEditTextarea(){return this.textarea&&!this.textarea.disabled&&!this.textarea.readOnly}getCleanHTML(){return this.getRenderedHTML({cleanHTML:!0})}focus(){this.textarea.focus()}blur(){this.textarea.blur()}isInitialized(){return this.initialized}reinit(e={}){var t,n;let r=(t=this.options)==null?void 0:t.toolbarButtons,i=(n=this.options)==null?void 0:n.disable;this.options=this._mergeOptions({...this.options,...e});let a=this.toolbar&&this.options.toolbar&&(Zn(r,this.options.toolbarButtons)||String(i)!==String(this.options.disable));this._rebuildActionsMap(),a&&(this._cleanupToolbarListeners(),this.toolbar.destroy(),this.toolbar=null,this._createToolbar()),this.fileUploadInitialized&&this._destroyFileUpload(),this.options.fileUpload&&this._initFileUpload(),this._applyOptions(),this.updatePreview()}showToolbar(){this.toolbar?this.toolbar.show():this._createToolbar()}hideToolbar(){this.toolbar&&this.toolbar.hide()}setTheme(e){if(_OverType._autoInstances.delete(this),this.instanceTheme=e,e===`auto`)_OverType._autoInstances.add(this),_OverType._startAutoListener(),this._applyResolvedTheme(Se(`auto`));else{let t=typeof e==`string`?w(e):e,n=typeof t==`string`?t:t.name;n&&this.container.setAttribute(`data-theme`,n),this._applyThemeVars(t),this.updatePreview()}return _OverType._stopAutoListener(),this}_applyResolvedTheme(e){let t=w(e);this.container.setAttribute(`data-theme`,e),this._applyThemeVars(t,!0),this.updatePreview()}_applyThemeVars(e,t=!1){if(!e||!e.colors)return;let n=Ce(e.colors,e.previewColors);this.container.style.cssText=t?n:this.container.style.cssText+n}setCodeHighlighter(e){this.options.codeHighlighter=e,this.updatePreview()}setCustomSyntax(e){this.options.customSyntax=e,this.updatePreview()}_parserOptions(){return{customSyntax:this.options.customSyntax,disable:this.options.disable}}_disabledFeatures(){return MarkdownParser.resolveDisabled(this.options.disable)}_withoutDisabledButtons(e){var t,n;let r=this._disabledFeatures();if(r.size===0)return e;let i=[];for(let n of e)r.has(Xn[n==null?void 0:n.actionId])||(n==null?void 0:n.name)===`separator`&&(i.length===0||((t=i[i.length-1])==null?void 0:t.name)===`separator`)||i.push(n);return((n=i[i.length-1])==null?void 0:n.name)===`separator`&&i.pop(),i}_updateStats(){if(!this.statsBar)return;let e=this.textarea.value,t=e.split(`
`),n=e.length,r=e.split(/\s+/).filter(e=>e.length>0).length,i=this.textarea.selectionStart,a=e.substring(0,i).split(`
`),o=a.length,s=a[a.length-1].length+1;this.options.statsFormatter?this.statsBar.innerHTML=this.options.statsFormatter({chars:n,words:r,lines:t.length,line:o,column:s}):this.statsBar.innerHTML=`
          <div class="overtype-stat">
            <span class="live-dot"></span>
            <span>${n} chars, ${r} words, ${t.length} lines</span>
          </div>
          <div class="overtype-stat">Line ${o}, Col ${s}</div>
        `}_setupAutoResize(){this.container.classList.add(`overtype-auto-resize`),this.previousHeight=null,this._updateAutoHeight(),this._autoResizeHandler||(this._autoResizeHandler=()=>this._updateAutoHeight(),this.textarea.addEventListener(`input`,this._autoResizeHandler),window.addEventListener(`resize`,this._autoResizeHandler))}_updateAutoHeight(){if(!this.options.autoResize)return;let e=this.textarea,t=this.preview,n=this.wrapper;if(this.container.dataset.mode===`preview`){n.style.removeProperty(`height`),t.style.removeProperty(`height`),t.style.removeProperty(`overflow-y`),e.style.removeProperty(`height`),e.style.removeProperty(`overflow-y`);return}let r=e.scrollTop;n.style.setProperty(`height`,`auto`,`important`),e.style.setProperty(`height`,`auto`,`important`);let i=e.scrollHeight;if(this.options.minHeight){let e=parseInt(this.options.minHeight);i=Math.max(i,e)}let a=`hidden`;if(this.options.maxHeight){let e=parseInt(this.options.maxHeight);i>e&&(i=e,a=`auto`)}let o=i+`px`;e.style.setProperty(`height`,o,`important`),e.style.setProperty(`overflow-y`,a,`important`),t.style.setProperty(`height`,o,`important`),t.style.setProperty(`overflow-y`,a,`important`),n.style.setProperty(`height`,o,`important`),e.scrollTop=r,t.scrollTop=r,this.previousHeight!==i&&(this.previousHeight=i)}showStats(e){this.options.showStats=e,e&&!this.statsBar?this._createStatsBar():e&&this.statsBar?this._updateStats():!e&&this.statsBar&&(this.statsBar.remove(),this.statsBar=null)}showNormalEditMode(){return this.container.dataset.mode=`normal`,this._syncPreviewInteractivity(),this.updatePreview(),this._updateAutoHeight(),requestAnimationFrame(()=>{this.textarea.scrollTop=this.preview.scrollTop,this.textarea.scrollLeft=this.preview.scrollLeft}),this}showPlainTextarea(){if(this.container.dataset.mode=`plain`,this._syncPreviewInteractivity(),this._updateAutoHeight(),this.toolbar){let e=this.container.querySelector(`[data-action="toggle-plain"]`);e&&(e.classList.remove(`active`),e.title=`Show markdown preview`)}return this}showPreviewMode(){return this.container.dataset.mode=`preview`,this._syncPreviewInteractivity(),this.updatePreview(),this._updateAutoHeight(),this}destroy(){if(_OverType._autoInstances.delete(this),_OverType._stopAutoListener(),this.fileUploadInitialized&&this._destroyFileUpload(),this.element.overTypeInstance=null,_OverType.instances.delete(this.element),this.shortcuts&&this.shortcuts.destroy(),this._safariReflowRaf&&(cancelAnimationFrame(this._safariReflowRaf),this._safariReflowRaf=null),this.linkTooltip&&(this.linkTooltip.destroy(),this.linkTooltip=null),this.toolbar&&(this._cleanupToolbarListeners(),this.toolbar.destroy(),this.toolbar=null),this._autoResizeHandler&&(this.textarea.removeEventListener(`input`,this._autoResizeHandler),window.removeEventListener(`resize`,this._autoResizeHandler),this._autoResizeHandler=null),this.wrapper)if(this.options.persist)[this.preview,this.placeholderEl,this.statsBar].forEach(e=>e==null?void 0:e.remove()),this.statsBar=null,this.wrapper._instance=null;else{let e=this.getValue();this.wrapper.remove(),this.element.textContent=e}this.initialized=!1}static init(e,t={}){return new _OverType(e,t)}static initFromData(e,t={}){return _OverType._resolveTargets(e).map(e=>{let n={...t};for(let t of e.attributes){if(!t.name.startsWith(`data-ot-`))continue;let e=t.name.slice(8);if(e.startsWith(`textarea-`)&&e!==`textarea-props`){let r=e.slice(9).replace(/-([a-z])/g,(e,t)=>t.toUpperCase());n.textareaProps={...n.textareaProps||{},[r]:_OverType._parseDataValue(t.value)};continue}let r=e.replace(/-([a-z])/g,(e,t)=>t.toUpperCase());n[r]=_OverType._parseDataValue(t.value)}return new _OverType(e,n)[0]})}static _resolveTargets(e){if(e==null)throw Error(`Invalid target: must be selector string, Element, NodeList, or Array`);if(typeof e==`string`)return Array.from(document.querySelectorAll(e));if(e instanceof Element)return[e];if(e instanceof NodeList)return Array.from(e);if(Array.isArray(e))return e;if(typeof e.length==`number`)return Array.from(e);throw Error(`Invalid target: must be selector string, Element, NodeList, or Array`)}static _parseDataValue(e){if(e===`true`)return!0;if(e===`false`)return!1;if(e===`null`)return null;if(e!==``&&!isNaN(Number(e)))return Number(e);let t=e.trim();if(t[0]===`{`||t[0]===`[`)try{return JSON.parse(t)}catch(t){return e}return e}static getInstance(e){let t;return t=e instanceof Element?e:_OverType._resolveTargets(e)[0],t&&(t.overTypeInstance||_OverType.instances.get(t))||null}static destroyAll(){document.querySelectorAll(`[data-overtype-instance]`).forEach(e=>{let t=_OverType.getInstance(e);t&&t.destroy()})}static injectStyles(e=!1){if(_OverType.stylesInjected&&!e)return;let t=document.querySelector(`style.overtype-styles`);t&&t.remove();let n=Te({theme:_OverType.currentTheme||C}),r=document.createElement(`style`);r.className=`overtype-styles`,_OverType.stylesChrome&&r.setAttribute(`clay`,`editor-ui`),r.textContent=n,document.head.appendChild(r),_OverType.stylesInjected=!0}static setTheme(e,t=null){if(_OverType._globalAutoTheme=!1,_OverType._globalAutoCustomColors=null,e===`auto`){_OverType._globalAutoTheme=!0,_OverType._globalAutoCustomColors=t,_OverType._startAutoListener(),_OverType._applyGlobalTheme(Se(`auto`),t);return}_OverType._stopAutoListener(),_OverType._applyGlobalTheme(e,t)}static _applyGlobalTheme(e,t=null){let n=typeof e==`string`?w(e):e;t&&(n=we(n,t)),_OverType.currentTheme=n,_OverType.injectStyles(!0);let r=typeof n==`string`?n:n.name;document.querySelectorAll(`.overtype-container`).forEach(e=>{let t=e.querySelector(`.overtype-wrapper`);r&&t&&t._instance&&e.setAttribute(`data-theme`,r)}),document.querySelectorAll(`.overtype-wrapper`).forEach(e=>{e.closest(`.overtype-container`)||r&&e.setAttribute(`data-theme`,r);let t=e._instance;t&&t.updatePreview()}),document.querySelectorAll(`overtype-editor`).forEach(e=>{r&&typeof e.setAttribute==`function`&&e.setAttribute(`theme`,r),typeof e.refreshTheme==`function`&&e.refreshTheme()})}static _startAutoListener(){_OverType._autoMediaQuery||window.matchMedia&&(_OverType._autoMediaQuery=window.matchMedia(`(prefers-color-scheme: dark)`),_OverType._autoMediaListener=e=>{let t=e.matches?`cave`:`solar`;_OverType._globalAutoTheme&&_OverType._applyGlobalTheme(t,_OverType._globalAutoCustomColors),_OverType._autoInstances.forEach(e=>e._applyResolvedTheme(t))},_OverType._autoMediaQuery.addEventListener(`change`,_OverType._autoMediaListener))}static _stopAutoListener(){_OverType._autoInstances.size>0||_OverType._globalAutoTheme||_OverType._autoMediaQuery&&(_OverType._autoMediaQuery.removeEventListener(`change`,_OverType._autoMediaListener),_OverType._autoMediaQuery=null,_OverType._autoMediaListener=null)}static setCodeHighlighter(e){MarkdownParser.setCodeHighlighter(e),document.querySelectorAll(`.overtype-wrapper`).forEach(e=>{let t=e._instance;t&&t.updatePreview&&t.updatePreview()}),document.querySelectorAll(`overtype-editor`).forEach(e=>{if(typeof e.getEditor==`function`){let t=e.getEditor();t&&t.updatePreview&&t.updatePreview()}})}static setCustomSyntax(e){MarkdownParser.setCustomSyntax(e),document.querySelectorAll(`.overtype-wrapper`).forEach(e=>{let t=e._instance;t&&t.updatePreview&&t.updatePreview()}),document.querySelectorAll(`overtype-editor`).forEach(e=>{if(typeof e.getEditor==`function`){let t=e.getEditor();t&&t.updatePreview&&t.updatePreview()}})}static _registerClaySnapshotHook(){var e;let t=typeof window<`u`?window:globalThis;if(t.__overtypeClaySnapshotHook)return;t.__overtypeClaySnapshotHook=!0;let n=()=>{var e,n;return(n=(e=t.clay)==null?void 0:e.onSnapshot)==null?void 0:n.call(e,_OverType._stripLayoutFromSnapshot)};typeof((e=t.clay)==null?void 0:e.onSnapshot)==`function`?n():document.addEventListener(`clay:ready`,n,{once:!0})}static _stripLayoutFromSnapshot(e){e.querySelectorAll(`textarea.overtype-input[persist]`).forEach(e=>{[e,e.closest(`.overtype-wrapper`)].forEach(e=>{e&&(e.style.removeProperty(`height`),e.style.removeProperty(`overflow-y`),e.getAttribute(`style`)||e.removeAttribute(`style`))})})}static initGlobalListeners(){let e=typeof window<`u`?window:globalThis,t=`__overtypeGlobalListenersInitialized`;if(_OverType.globalListenersInitialized||e[t]){_OverType.globalListenersInitialized=!0;return}e[t]=!0,document.addEventListener(`input`,e=>{if(e.target&&e.target.classList&&e.target.classList.contains(`overtype-input`)){let t=e.target.closest(`.overtype-wrapper`),n=t==null?void 0:t._instance;n&&n.handleInput(e)}}),document.addEventListener(`keydown`,e=>{if(e.target&&e.target.classList&&e.target.classList.contains(`overtype-input`)){let t=e.target.closest(`.overtype-wrapper`),n=t==null?void 0:t._instance;n&&n.handleKeydown(e)}}),document.addEventListener(`click`,e=>{if(e.target&&e.target.classList&&e.target.classList.contains(`overtype-input`)){let t=e.target.closest(`.overtype-wrapper`),n=t==null?void 0:t._instance;n&&n._handleTaskClick(e)}}),document.addEventListener(`clay:sync-applied`,()=>{document.querySelectorAll(`.overtype-wrapper`).forEach(e=>{let t=e._instance;if(!(!t||!t.options.persist))try{t._refreshFromTextarea()}catch(e){console.error(`OverType: redraw after clay:sync-applied failed`,e)}})}),document.addEventListener(`focus`,e=>{if(e.target&&e.target.classList&&e.target.classList.contains(`overtype-input`)){let t=e.target.closest(`.overtype-wrapper`),n=t==null?void 0:t._instance;n&&n.handleFocus(e)}},!0),document.addEventListener(`blur`,e=>{if(e.target&&e.target.classList&&e.target.classList.contains(`overtype-input`)){let t=e.target.closest(`.overtype-wrapper`),n=t==null?void 0:t._instance;n&&n.handleBlur(e)}},!0),document.addEventListener(`scroll`,e=>{if(e.target&&e.target.classList&&e.target.classList.contains(`overtype-input`)){let t=e.target.closest(`.overtype-wrapper`),n=t==null?void 0:t._instance;n&&n.handleScroll(e)}},!0),document.addEventListener(`selectionchange`,e=>{let t=document.activeElement;if(t&&t.classList.contains(`overtype-input`)){let e=t.closest(`.overtype-wrapper`),n=e==null?void 0:e._instance;n&&(n.options.showStats&&n.statsBar&&n._updateStats(),clearTimeout(n._selectionTimeout),n._selectionTimeout=setTimeout(()=>{n.updatePreview()},50))}}),_OverType.globalListenersInitialized=!0}};r(Q,`instances`,/* @__PURE__ */ new WeakMap),r(Q,`stylesInjected`,!1),r(Q,`stylesChrome`,!1),r(Q,`globalListenersInitialized`,!1),r(Q,`instanceCount`,0),r(Q,`_autoMediaQuery`,null),r(Q,`_autoMediaListener`,null),r(Q,`_autoInstances`,/* @__PURE__ */ new Set),r(Q,`_globalAutoTheme`,!1),r(Q,`_globalAutoCustomColors`,null);var $=Q;$.MarkdownParser=MarkdownParser,$.ShortcutsManager=ShortcutsManager,$.themes={solar:C,cave:w(`cave`)},$.getTheme=w,$.currentTheme=C;var Qn=$;
/**
* OverType - A lightweight markdown editor library with perfect WYSIWYG alignment
* @version 1.0.0
* @license MIT
*/
export{$ as OverType,Qn as default,Kn as defaultToolbarButtons,Ee as markdownActions,X as toolbarButtons};

