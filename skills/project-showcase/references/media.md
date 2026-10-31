# Media: screenshots, clips, GIFs

## Web apps (Playwright)
- Edit `site/scripts/capture.mjs` STEPS block. Desktop 1440x900, phone 390x844 @2x. Light and dark only when the site shows both.
- Seeded/synthetic data only; never real user data. Scripts that create records need a disposable stack.
- Wait for `networkidle`, `document.fonts.ready`, then ~600ms for entrance animation. Grow the viewport rather than `fullPage` for tall pages (sticky headers mis-render).
- Name by content: `settings-desktop`, `checkout-phone`. `verify.mjs` fails on referenced-but-missing and warns on unused images.

## Clips
- 5-12 s, one idea, silent, looping. Record with Playwright `recordVideo` or `screencast`; trim dead time.
- Convert: `ffmpeg -i in.webm -c:v libvpx-vp9 -b:v 0 -crf 36 -an public/clips/NAME.webm` and `ffmpeg -i in.webm -c:v libx264 -crf 28 -pix_fmt yuv420p -an public/clips/NAME.mp4`. Aim < 1.5 MB each.
- README cannot embed video reliably: use a GIF (`ffmpeg -vf "fps=12,scale=800:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse"`) kept < 5 MB, linked to the site clip.
- `<Clip>` is lazy, muted, plays only when visible, never autoplays under reduced motion (poster shows).

## CLI / TUI / library
- Terminal sessions: `vhs` (tape files, outputs GIF/WebM/MP4) or `asciinema` + `agg`. Script the session so it is reproducible; commit the tape.
- Libraries: show a short real snippet plus its output in `<Terminal>`; no fake UI.

## Check
Open every capture. Cropped, empty-state, or error screens are the common failure.
