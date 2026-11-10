# 09: Settings and Acknowledgements

**What to build:** A Settings screen with a toggle to hide pinyin (saved in Learner Progress, applied in every Exercise), and an Acknowledgements screen listing every third-party source used in the Course Content with its license. The content build fails if any source lacks an Acknowledgement.

**Blocked by:** 02

**Status:** done

- [x] Settings screen reachable from the Lesson path
- [x] Pinyin toggle hides pinyin in Exercises; setting survives app restart
- [x] Acknowledgements screen lists each source, author, license and link from the Course Content
- [x] Content build fails with a clear message if a source has no Acknowledgement

## Comments

Done. Settings (gear on the Lesson path): "Show pinyin" switch saved in Learner Progress (schema v4 `settings` table) and applied to every Word shown in an Exercise. The one exception: a listening Exercise on a device with no Chinese voice still shows pinyin, since that is the only way to answer it.

Acknowledgements: the content source has an `acknowledgements` list (`id`, `name`, `author`, `license`, `url`, all required) and a Word may cite one with `"source": "<id>"`. The build fails with a clear message if a cited source has no Acknowledgement or one is missing a field. The screen lists them from the Course Content; with the current original fixture it says no third-party sources are used. Ticket 08 should make Tone Recordings cite their source the same way. Links are shown as selectable text (no url_launcher yet).
