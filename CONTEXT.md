# Miniharp

Miniharp maintains a small project-scoped loop of files and shows their relationship to the user’s current editing context.

## Language

**File mark**:
A file saved as a member of the current Miniharp loop.
_Avoid_: Current mark, indicator

**Current indicator**:
The transient designation of the file mark whose file is active in the most recently focused editor window. It is absent when that file is not in the loop; focusing the Miniharp list itself does not change it.
_Avoid_: Mark, selection

**Loop position**:
The position of the current file within the Miniharp loop. It is absent when the current file is not marked, so forward navigation starts at the first file and backward navigation starts at the last.
_Avoid_: Current mark, selected item
