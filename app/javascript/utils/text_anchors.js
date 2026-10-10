// Selection → block anchor math shared by the markdown paper (text_selection_controller)
// and the HTML viewer's in-frame client. The frame has an opaque origin and cannot import
// app modules, so HtmlFrameDocument inlines this file into the frame at serve time.
// Keep it dependency-free.

export function blockIdOf(block) {
    return block.dataset.docnotateBlock ?? block.id
}

export function selectedLeafBlocks(blocks, range) {
    const selectedBlocks = blocks.filter(block => blockContainsSelectedText(range, block))

    // Keep only leaf blocks: exclude ancestors of other selected blocks so a
    // nested paragraph inside a list is used instead of the enclosing list.
    return selectedBlocks.filter(block => !selectedBlocks.some(other => block !== other && block.contains(other)))
}

export function computeBlockOffsets(range, startBlockEl, endBlockEl) {
    let startTextNode = range.startContainer
    let startLocalOffset = range.startOffset
    if (startTextNode.nodeType !== Node.TEXT_NODE) {
        startTextNode = resolveTextNode(startTextNode, startLocalOffset, true)
        startLocalOffset = 0
    }

    let endTextNode = range.endContainer
    let endLocalOffset = range.endOffset
    if (endTextNode.nodeType !== Node.TEXT_NODE) {
        endTextNode = resolveTextNode(endTextNode, endLocalOffset, false)
        endLocalOffset = endTextNode ? endTextNode.textContent.length : 0
    }

    return {
        startOffset: offsetWithinBlock(startTextNode, startLocalOffset, startBlockEl),
        endOffset: offsetWithinBlock(endTextNode, endLocalOffset, endBlockEl)
    }
}

export function extractPrefix(range) {
    const node = range.startContainer
    if (node.nodeType !== Node.TEXT_NODE) return ""

    const text = node.textContent
    const prefixStart = Math.max(0, range.startOffset - 50)
    return text.slice(prefixStart, range.startOffset).trimStart()
}

export function extractPostfix(range) {
    const node = range.endContainer
    if (node.nodeType !== Node.TEXT_NODE) return ""

    const text = node.textContent
    const postfixEnd = Math.min(text.length, range.endOffset + 50)
    return text.slice(range.endOffset, postfixEnd).trimEnd()
}

// Wraps the range's text in <mark> elements and returns them so they can be unwrapped later.
export function highlightRange(range, root) {
    const marks = []
    const walker = document.createTreeWalker(
        root,
        NodeFilter.SHOW_TEXT,
        {
            acceptNode: (node) => {
                if (node.parentNode.closest("mark")) return NodeFilter.FILTER_REJECT
                return NodeFilter.FILTER_ACCEPT
            }
        },
        false
    )

    let textNode
    while ((textNode = walker.nextNode()) !== null) {
        if (!rangeIntersectsNode(range, textNode)) continue

        const nodeStart = 0
        const nodeEnd = textNode.textContent.length
        const startOffset = textNode === range.startContainer ? range.startOffset : nodeStart
        const endOffset = textNode === range.endContainer ? range.endOffset : nodeEnd

        if (startOffset >= endOffset) continue

        const parent = textNode.parentNode
        textNode.splitText(endOffset)
        const highlightNode = textNode.splitText(startOffset)
        const mark = document.createElement("mark")

        mark.className = "document__selection-highlight"
        mark.textContent = highlightNode.textContent
        parent.replaceChild(mark, highlightNode)
        marks.push(mark)
    }

    return marks
}

export function unwrapHighlights(marks, root) {
    marks.forEach(mark => {
        mark.replaceWith(document.createTextNode(mark.textContent))
    })
    root.normalize()
}

function blockContainsSelectedText(range, block) {
    const walker = document.createTreeWalker(block, NodeFilter.SHOW_TEXT, null, false)
    let textNode
    while ((textNode = walker.nextNode()) !== null) {
        if (!rangeIntersectsNode(range, textNode)) continue

        const nodeLength = textNode.textContent.length
        const start = textNode === range.startContainer ? range.startOffset : 0
        const end = textNode === range.endContainer ? range.endOffset : nodeLength

        if (start < end) return true
    }

    return false
}

function rangeIntersectsNode(range, node) {
    if (range.intersectsNode) {
        return range.intersectsNode(node)
    }

    // Fallback for browsers without range.intersectsNode
    const nodeRange = document.createRange()
    nodeRange.selectNode(node)
    return range.compareBoundaryPoints(Range.START_TO_END, nodeRange) <= 0 &&
        range.compareBoundaryPoints(Range.END_TO_START, nodeRange) >= 0
}

function resolveTextNode(container, offset, isStart) {
    if (container.nodeType === Node.TEXT_NODE) return container

    const child = isStart ? container.childNodes[offset] : container.childNodes[offset - 1]
    if (!child) return null

    const walker = document.createTreeWalker(child, NodeFilter.SHOW_TEXT, null, false)
    if (isStart) {
        return walker.nextNode()
    }

    let last = null
    let node
    while ((node = walker.nextNode()) !== null) {
        last = node
    }
    return last
}

function offsetWithinBlock(textNode, localOffset, blockEl) {
    if (!blockEl.contains(textNode)) return localOffset

    const walker = document.createTreeWalker(blockEl, NodeFilter.SHOW_TEXT, null, false)
    let offset = 0
    let node
    while ((node = walker.nextNode()) !== null) {
        if (node === textNode) return offset + localOffset
        offset += node.textContent.length
    }
    return localOffset
}
