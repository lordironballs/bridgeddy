<p align="center"><img src="docs/icon.png" width="128" alt="BridgEddy"></p>

<h1 align="center">BridgEddy</h1>

<p align="center">Open another user's session on the same Mac in a window — and undo everything when you're done.</p>

<p align="center"><a href="README.pt-BR.md">Português</a> · <a href="README.es.md">Español</a></p>

---

## Why

macOS Screen Sharing can open a **separate, virtual session** for a different user, but it refuses to connect to your own Mac ("Screen Sharing is not permitted on localhost"). The classic workaround is an SSH tunnel typed into Terminal. BridgEddy does that in one click.

Handy when you keep a personal and a work account on the same Mac and need apps from both at the same time.

## What it does

1. You pick the target user and click **Connect**.
2. If **Screen Sharing** or **Remote Login** are off, it turns them on (one administrator password prompt).
3. It creates a **temporary SSH key**, restricted to this Mac and to the Screen Sharing port only, and opens a local tunnel.
4. It opens Screen Sharing at `vnc://localhost:590x` and copies the user name to the clipboard. Sign in and choose to open a separate session.
5. When you close the Screen Sharing window, it **undoes everything**: closes the tunnel, deletes the key and turns off only the services it turned on — even if the app quits or crashes.

If the connection drops right after login with "not permitted on localhost", Screen Sharing is stuck: BridgEddy offers a **Restart Screen Sharing** button and reconnects.

## Build

Requires macOS 13+ and the Xcode command line tools (`xcode-select --install`).

```bash
./build.sh                 # builds, installs to ~/Applications and opens
SKIP_INSTALL=1 ./build.sh  # only builds into build/
```

## Known limitations

- The virtual session inherits the Mac's physical displays; use Screen Sharing's display menu to show just one.
- Audio and graphics acceleration inside the virtual session are limited.
- On some macOS versions, turning Screen Sharing on from the command line is blocked; BridgEddy then opens the Sharing settings so you can switch it on.

## Support

BridgEddy is free and open source. If it helped you, a thank-you donation keeps the project going ❤️

- 🇧🇷 **PIX:** `pix@xwa.com.br` (or **Support the project** inside the app for the QR code)
- 🌎 **[GitHub Sponsors](https://github.com/sponsors/lordironballs)**
- ⭐ Starring the repo and telling friends helps a lot too!

## License

[MIT](LICENSE) © 2026 [Eddy Antonini](https://eddyantonini.com.br)
