# Design

## Scene

A person at a Mac, day or night, sorting a private shelf of games. Light mode is morning paper. Dark mode is the same ink under a lamp. The accent is lamp amber.

## Layout

One window. A rail of four filters, the shelf, and one trailing pane. The pane is the empty invitation, the open game, or add. Those three never stack.

## Type and color

System text. Titles are semibold. Counts use monospaced digits. Amber marks the selected filter, the open spine, the rating, and the primary add action. Secondary text is a brown-gray mixed from the same ink, not a neutral gray on a colored ground.

## Motion

The trailing pane fades in and shifts 14 points from the right over 280ms, with a fast ease-out. Reduce Motion uses a 120ms fade and no shift. Status chips on a spine update in the same timing.

## Controls

Filters are plain buttons with an opaque row so the whole row receives the click. Statuses are macOS checkboxes. The rating is a menu. Add and the open game share the trailing pane.
