## 2024-05-18 - Exposing hidden swipe gestures to screen readers
**Learning:** Hidden actions triggered by horizontal drag gestures (like `GestureDetector` onHorizontalDragUpdate) are completely invisible to screen readers by default. Relying solely on these custom gestures locks out users relying on TalkBack/VoiceOver.
**Action:** When implementing custom swipeable cards or hidden reveals using `GestureDetector`, always wrap the interactive element in a `Semantics` widget and map the hidden actions to the native accessibility action menu using `customSemanticsActions`.
