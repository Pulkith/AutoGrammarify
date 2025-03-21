# AutoGrammarify

A background macOS app that can fix the grammar, syntax, punctuation, semantics, etc... of text anywhere on your laptop. AutoGrammarify (GFy) runs in the background and is always active. Pressing CMD+SHIFT+H with any selected text will run the algorithm and replace your text with the corrected version. Leveraging a Small Language Model, GFy maintains context and meaning much better than any current algorithm. You can choose from multiple styles in the menu bar to rewrite text in different tones. It's a free and lightweight version of Apple Intelligence! The average latency is < 0.5s!

## Future TODOs:
- Use Diff so that the SLM only needs to output new changes, instead of the entire response
- Use Streaming to reduce first-token latency
- Add assignable Hotkeys
- Rewrite using customizable prompt

## Requires
- Accepting (or adding) Accessibility Permissions in Settings
- Ollama with Gemma3:1b installed (on default port)